import java.io.File;
import java.io.FileInputStream;
import java.io.FileReader;
import java.io.InputStreamReader;
import java.io.PrintStream;
import java.io.Reader;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.zip.GZIPInputStream;

import com.staktrace.util.conv.json.JsonReader;
import com.staktrace.util.conv.string.StringHash;

public class Plotter {
    private final Set<String> _paths;
    private final List<String> _folders;
    private final List<Map<String, Long>> _values;

    Plotter() {
        _paths = new TreeSet<String>();
        _folders = new ArrayList<String>();
        _values = new ArrayList<Map<String, Long>>();
    }

    public void loadData( String folder, Reader data ) throws Exception {
        Map<String, Long> values = Parser.toMap( new JsonReader( data ).readObject() );
        for (String path : values.keySet()) {
            _paths.add( path );
        }
        _folders.add( folder );
        _values.add( values );
    }

    public void sanitize() {
        Set<String> toDrop = new TreeSet<String>();
        for (String path : _paths) {
            boolean allEqual = true;
            Long equalValue = null;

            int misses = 0;
            for (Map<String, Long> data : _values) {
                if (!data.containsKey( path )) {
                    misses++;
                    data.put( path, 0L );
                }
                if (equalValue == null) {
                    equalValue = data.get( path );
                } else if (allEqual && data.get( path ).longValue() != equalValue.longValue()) {
                    allEqual = false;
                }
            }
            if (misses > 0) {
                System.err.println( "INFO: Path [" + path + "] had " + misses + " misses (" + (misses * 100.0 / _values.size()) + "%)" );
            }
            if (allEqual) {
                System.err.println( "INFO: Path [" + path + "] had all equal values (" + equalValue + "); dropping" );
                toDrop.add( path );
            }
        }
        for (String drop : toDrop) {
            _paths.remove( drop );
        }
        System.err.println( "INFO: Remaining number of interesting columns: " + _paths.size() );
    }

    public void dumpDataFile( PrintStream out ) throws Exception {
        for (int i = 0; i < _values.size(); i++) {
            Map<String, Long> data = _values.get( i );
            out.print( (i + 1) );
            for (String path : _paths) {
                out.print( ' ' );
                out.print( data.get( path ) );
            }
            out.println();
        }
    }

    public void dumpPlotFile( String dataFile, PrintStream out ) throws Exception {
        out.println( "set terminal png size 800,640" );
        out.println( "set key off" );
        int column = 2;
        for (String path : _paths) {
            out.println( "set output 'graph-" + StringHash.hash( path ) + ".png'" );
            out.println( "plot '" + dataFile + "' using 1:" + column );
            column++;
        }
    }

    private void groupPaths( Set<String> paths, String base, List<List<String>> out ) {
        List<String> group = new ArrayList<String>();
        for (String path : paths) {
            if (path.startsWith( base ) && path.indexOf( '/', base.length() ) < 0) {
                group.add( path );
            }
        }
        if (group.size() == 0) {
            return;
        }
        out.add( group );
        for (String newBase : group) {
            groupPaths( paths, newBase + "/", out );
        }
    }

    private List<List<String>> groupPaths( Set<String> paths ) {
        List<List<String>> ret = new ArrayList<List<String>>();
        groupPaths( paths, "", ret );
        return ret;
    }

    public void dumpIndexFile( PrintStream out ) throws Exception {
        out.println( "<!DOCTYPE html><html><head><title>AWSY-mobile plotter results</title>" );
        out.println( "<style>div.group { border: solid 1px black }" );
        out.println( "       div.item { display: inline-block; text-align: center } </style>" );
        out.println( "<script>function toggle(elem) {" );
        out.println( "   var id = elem.getAttribute('data-target');" );
        out.println( "   var e = document.getElementById(id);" );
        out.println( "   var hidden = (e.style.display == 'none');" );
        out.println( "   e.style.display = (hidden ? 'block' : 'none');" );
        out.println( "   elem.innerHTML = (hidden ? 'Collapse' : 'Expand');" );
        out.println( "}; window.onload = function() {" );
        out.println( "   var toggles = document.getElementsByClassName('toggle');" );
        out.println( "   for (i = toggles.length - 1; i >= 0; i--) {" );
        out.println( "     if (document.getElementById(toggles[i].getAttribute('data-target')) == null) {" );
        out.println( "       toggles[i].parentNode.removeChild(toggles[i]);" );
        out.println( "     }" );
        out.println( "   }" );
        out.println( "} </script>" );
        out.println( "</head><body><h1>Interesting data graphs:</h1>" );
        List<List<String>> grouped = groupPaths( _paths );
        for (List<String> group : grouped) {
            String style = "display:none";
            String id = group.get( 0 );
            if (id.lastIndexOf( '/' ) >= 0) {
                id = id.substring( 0, id.lastIndexOf( '/' ) );
            } else {
                id = "(root)";
                style = "display:block";
            }
            out.println( "<div class='group' id='" + StringHash.hash( id ) + "' style='" + style + "'>" );
            out.println( "<h2><pre>" + id + "</pre></h2>" );
            for (String path : group) {
                out.println( "<div class='item'><a href='graph-" + StringHash.hash( path ) + ".png'><img title='" + path.replaceAll( "\'", "&apos;" ) + "' src='thumb-" + StringHash.hash( path ) + ".png'/></a><br>&nbsp;<a href='#' class='toggle' data-target='" + StringHash.hash( path ) + "' onclick='toggle(this)'>Expand</a></div>" );
            }
            out.println( "</div>" );
        }
        out.println( "<h1>Folders for data points:</h1><ol>" );
        for (int i = 0; i < _values.size(); i++) {
            if (_folders.get( i ) == null) {
                out.println( "<li>(unknown)</li>" );
            } else {
                out.println( "<li><a href='http://areweslimyet.mobi/" + _folders.get( i ) + "/'>" + _folders.get( i ) + "</a></li>" );
            }
        }
        out.println( "</ol></body></html>" );
    }

    public static void main( String[] args ) throws Exception {
        if (args.length == 0) {
            System.err.println( "Usage: java Plotter <folder>/<file1.json[.gz]> [<folder>/<file2.json[.gz]> [...]]" );
            return;
        }

        Plotter t = new Plotter();
        for (String arg : args) {
            Reader fr;
            if (arg.endsWith( ".gz" )) {
                fr = new InputStreamReader( new GZIPInputStream( new FileInputStream( arg ) ) );
            } else {
                fr = new FileReader( arg );
            }
            t.loadData( new File( arg ).getParent(), fr );
            fr.close();
        }
        t.sanitize();
        PrintStream ps = new PrintStream( "table.data" );
        t.dumpDataFile( ps );
        ps.close();
        ps = new PrintStream( "table.plot" );
        t.dumpPlotFile( "table.data", ps );
        ps.close();
        ps = new PrintStream( "table.html" );
        t.dumpIndexFile( ps );
        ps.close();
    }
}
