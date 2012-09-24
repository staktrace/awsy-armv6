var Cc = Components.classes;
var Ci = Components.interfaces;
var Cu = Components.utils;

Cu.import("resource://gre/modules/Services.jsm");

function dump(a) {
    Cc["@mozilla.org/consoleservice;1"].getService(Ci.nsIConsoleService).logStringMessage(a);
}

var kUrls = [
    "http://localhost:8001/tp5/thesartorialist.blogspot.com/thesartorialist.blogspot.com/index.html",
    "http://localhost:8002/tp5/cakewrecks.blogspot.com/cakewrecks.blogspot.com/index.html",
    "http://localhost:8003/tp5/baidu.com/www.baidu.com/s@wd=mozilla.html",
    //"http://localhost:8004/tp5/en.wikipedia.org/en.wikipedia.org/wiki/Rorschach_test.html",   // redirects to mobile site and fails
    "http://localhost:8005/tp5/twitter.com/twitter.com/ICHCheezburger.html",
    "http://localhost:8006/tp5/msn.com/www.msn.com/index.html",
    "http://localhost:8007/tp5/yahoo.co.jp/www.yahoo.co.jp/index.html",
    "http://localhost:8008/tp5/amazon.com/www.amazon.com/Kindle-Wireless-Reader-Wifi-Graphite/dp/B002Y27P3M/507846.html",
    "http://localhost:8009/tp5/linkedin.com/www.linkedin.com/in/christopherblizzard@goback=.nppvan_%252Flemuelf.html",
    "http://localhost:8010/tp5/bing.com/www.bing.com/search@q=mozilla&go=&form=QBLH&qs=n&sk=&sc=8-0.html",
    "http://localhost:8011/tp5/icanhascheezburger.com/icanhascheezburger.com/index.html",
    "http://localhost:8012/tp5/yandex.ru/yandex.ru/yandsearch@text=mozilla&lr=21215.html",
    "http://localhost:8013/tp5/cgi.ebay.com/cgi.ebay.com/ALL-NEW-KINDLE-3-eBOOK-WIRELESS-READING-DEVICE-W-WIFI-/130496077314@pt=LH_DefaultDomain_0&hash=item1e622c1e02.html",
    "http://localhost:8014/tp5/163.com/www.163.com/index.html",
    "http://localhost:8015/tp5/mail.ru/mail.ru/index.html",
    "http://localhost:8016/tp5/bbc.co.uk/www.bbc.co.uk/news/index.html",
    "http://localhost:8017/tp5/store.apple.com/store.apple.com/us@mco=Nzc1MjMwNA.html",
    "http://localhost:8018/tp5/imdb.com/www.imdb.com/title/tt1099212/index.html",
    "http://localhost:8019/tp5/mozilla.com/www.mozilla.com/en-US/firefox/all-older.html",
    "http://localhost:8020/tp5/ask.com/www.ask.com/web@q=What%27s+the+difference+between+brown+and+white+eggs%253F&gc=1&qsrc=3045&o=0&l=dir.html",
    "http://localhost:8021/tp5/cnn.com/www.cnn.com/index.html",
    "http://localhost:8022/tp5/sohu.com/www.sohu.com/index.html",
    "http://localhost:8023/tp5/vkontakte.ru/vkontakte.ru/help.php@page=about.html",
    "http://localhost:8024/tp5/youku.com/www.youku.com/index.html",
    "http://localhost:8025/tp5/myparentswereawesome.tumblr.com/myparentswereawesome.tumblr.com/index.html",
];

var gWindow = null;
var gTabsOpened = 0;

function setPreferences() {
    var prefs = [
        {   name: "network.proxy.socks",                type: "string", value: "localhost"  },
        {   name: "network.proxy.socks_port",           type: "int",    value: 9000         },
        {   name: "network.proxy.socks_remote_dns",     type: "bool",   value: true         },
        {   name: "network.proxy.type",                 type: "int",    value: 1            },
        {   name: "plugin.disable",                     type: "bool",   value: true         },
    ];
    prefs.forEach(function(pref) {
        Services.obs.notifyObservers(null, "Preferences:Set", JSON.stringify(pref));
    });
}

function logMemory(aLabel) {
    Services.obs.notifyObservers(null, "Memory:Dump", aLabel);
}

function doFullGc(aCallback, aIterations) {
    var threadMan = Cc["@mozilla.org/thread-manager;1"].getService(Ci.nsIThreadManager);
    var domWindowUtils = gWindow.QueryInterface(Components.interfaces.nsIInterfaceRequestor).getInterface(Components.interfaces.nsIDOMWindowUtils);

    function runSoon(f) {
        threadMan.mainThread.dispatch({ run: f }, Ci.nsIThread.DISPATCH_NORMAL);
    }

    function cc() {
        if (domWindowUtils.cycleCollect) {
            domWindowUtils.cycleCollect();
        }
        Services.obs.notifyObservers(null, "child-cc-request", null);
    }

    function minimizeInner() {
        // In order of preference: schedulePreciseShrinkingGC, schedulePreciseGC
        // garbageCollect
        if (++j <= aIterations) {
            var schedGC = Cu.schedulePreciseShrinkingGC;
            if (!schedGC) {
                schedGC = Cu.schedulePreciseGC;
            }

            Services.obs.notifyObservers(null, "child-gc-request", null);

            if (schedGC) {
                schedGC.call(Cu, { callback: function () {
                    runSoon(function () { cc(); runSoon(minimizeInner); });
                } });
            } else {
                if (domWindowUtils.garbageCollect) {
                    domWindowUtils.garbageCollect();
                }
                runSoon(function () { cc(); runSoon(minimizeInner); });
            }
        } else {
            runSoon(aCallback);
        }
    }

    var j = 0;
    minimizeInner();
}

function setTimeout(func, delay) {
    gWindow.setTimeout(func.bind(this), delay);
}

function assertWindow() {
    if (gWindow == null) {
        finish();
        return false;
    }
    return true;
}

function attachTo(aWindow) {
    if (gWindow != null) {
        dump("Fennec-addon-aboutmem: attempting to attach to a second window [" + aWindow + "] while already attached to one window [" + gWindow + "]");
        return;
    }
    gWindow = aWindow;
    setPreferences();
    setTimeout(startTest, 0);
}

function startTest() {
    if (!assertWindow()) return;

    logMemory("Start");
    setTimeout(settle, 30000);
}

function settle() {
    logMemory("StartSettled");
    openTab();
}

function openTab() {
    if (!assertWindow()) return;

    var urlIndex = gTabsOpened++;
    if (urlIndex >= kUrls.length) {
        logMemory("TabsOpen");
        setTimeout(postOpening, 30000);
        return;
    }

    dump("AWSY: opening tab with url [" + kUrls[urlIndex] + "]");
    gLastTab = gWindow.BrowserApp.addTab(kUrls[urlIndex], { selected: true });
    setTimeout(waitForTab, 10000);
}

function waitForTab() {
    if (!assertWindow()) return;

    if (gLastTab.browser.contentDocument.readyState === "complete") {
        gLastTab = null;
        openTab();
    } else {
        setTimeout(waitForTab, 10000);
    }
}

function postOpening() {
    if (!assertWindow()) return;

    logMemory("TabsOpenSettled");
    doFullGc(closeTabs.bind(this), 50);
}

function closeTabs() {
    if (!assertWindow()) return;

    logMemory("TabsOpenForceGC");
    var tabCount = gWindow.BrowserApp.tabs.length;
    for (var i = 1; i < tabCount; i++) {
        gWindow.BrowserApp.closeTab(gWindow.BrowserApp.tabs[i]);
    }

    var closeListener = {
        observe: function(aSubject, aTopic, aData) {
            if (!assertWindow()) return;
            tabCount--;
            dump("AWSY: tab count dropped to [" + tabCount + "]");
            if (tabCount == 1) {
                Services.obs.removeObserver(this, "Tab:Closed", false);
                setTimeout(tabsClosed, 0);
            }
        }
    };
    Services.obs.addObserver(closeListener, "Tab:Closed", false);
}

function tabsClosed() {
    if (!assertWindow()) return;

    logMemory("TabsClosed");
    setTimeout(postClosing, 30000);
}

function postClosing() {
    if (!assertWindow()) return;

    logMemory("TabsClosedSettled");
    doFullGc(function() {
        logMemory("TabsClosedForceGC");
        finish();
    }.bind(this), 50);
}

function finish() {
    dump("AWSY-ARMV6-DONE");
}

function detachFrom(aWindow) {
    if (gWindow == aWindow) {
        gWindow = null;
    }
}

var browserListener = {
    onOpenWindow: function(aWindow) {
        var win = aWindow.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindow);
        win.addEventListener("UIReady", function listener(aEvent) {
            win.removeEventListener("UIReady", listener, false);
            attachTo(win);
        }, false);
    },

    onCloseWindow: function(aWindow) {
        detachFrom(aWindow);
    },

    onWindowTitleChange: function(aWindow, aTitle) {
    }
};

function startup(aData, aReason) {
    var enumerator = Services.wm.getEnumerator("navigator:browser");
    while (enumerator.hasMoreElements()) {
        // potential race condition here - the window may not be ready yet at
        // this point, so ideally we would test for that. but i can't find a
        // property that reflects whether or not UIReady has been fired, so
        // for now just assume the window is ready
        attachTo(enumerator.getNext().QueryInterface(Ci.nsIDOMWindow));
    }
    Services.wm.addListener(browserListener);
}

function shutdown(aData, aReason) {
    // When the application is shutting down we normally don't have to clean
    // up any UI changes made
    if (aReason == APP_SHUTDOWN)
        return;

    Services.wm.removeListener(browserListener);
    var enumerator = Services.wm.getEnumerator("navigator:browser");
    while (enumerator.hasMoreElements()) {
        detachFrom(enumerator.getNext().QueryInterface(Ci.nsIDOMWindow));
    }
}

function install(aData, aReason) {
    // nothing to do
}

function uninstall(aData, aReason) {
    // nothing to do
}
