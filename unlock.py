from com.android.monkeyrunner import MonkeyRunner, MonkeyDevice
import os

device = MonkeyRunner.waitForConnection()
device.drag((20, 180), (300, 180))
