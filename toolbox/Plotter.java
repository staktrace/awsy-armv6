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
    private final List<Map<String, Long>> _values;

    Plotter() {
        _paths = new TreeSet<String>();
        _values = new ArrayList<Map<String, Long>>();
    }

    public void loadData( Reader data ) throws Exception {
        Map<String, Long> values = Parser.toMap( new JsonReader( data ).readObject() );
        for (String path : values.keySet()) {
            _paths.add( path );
        }
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
        out.println( "set terminal png size 600,400" );
        int column = 2;
        for (String path : _paths) {
            out.println( "set title \"" + path.replace( '"', '\'' ) + "\"" );
            out.println( "set output 'hash" + StringHash.toLong( path ) + ".png'" );
            out.println( "plot '" + dataFile + "' using 1:" + column );
            column++;
        }
    }

    public static void main( String[] args ) throws Exception {
        if (args.length == 0) {
            System.err.println( "Usage: java Plotter <file1.json[.gz]> [<file2.json[.gz]> [...]]" );
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
            t.loadData( fr );
            fr.close();
        }
        t.sanitize();
        PrintStream ps = new PrintStream( "table.data" );
        t.dumpDataFile( ps );
        ps.close();
        ps = new PrintStream( "table.plot" );
        t.dumpPlotFile( "table.data", ps );
        ps.close();
    }
}
