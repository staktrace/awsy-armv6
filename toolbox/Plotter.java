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

    public void dumpIndexFile( PrintStream out ) throws Exception {
        out.println( "<!DOCTYPE html><html><head><title>AWSY-ARMv6 plotter results</title></head><body>" );
        out.println( "<h1>Interesting data graphs:</h1>" );
        for (String path : _paths) {
            out.println( "<a href='graph-" + StringHash.hash( path ) + ".png'><img title='" + path.replaceAll( "\'", "&apos;" ) + "' src='thumb-" + StringHash.hash( path ) + ".png'/></a>" );
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
