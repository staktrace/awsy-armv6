import java.io.InputStreamReader;
import java.io.Reader;
import java.math.BigInteger;
import java.util.Map;
import java.util.TreeMap;

import com.staktrace.util.conv.json.JsonArray;
import com.staktrace.util.conv.json.JsonObject;
import com.staktrace.util.conv.json.JsonReader;

public class Dumper {
    private final Map<String, Long> _data;

    Dumper( Reader in ) throws Exception {
        _data = toMap( new JsonReader( in ).readObject() );
    }

    private void add( Map<String, Long> map, String path, long value ) {
        Long old = map.get( path );
        if (old == null) {
            map.put( path, value );
        } else {
            map.put( path, value + old );
        }
    }

    private Map<String, Long> toMap( JsonObject memDump ) {
        Map<String, Long> map = new TreeMap<String, Long>();
        JsonArray reports = (JsonArray)memDump.getValue( "reports" );
        for (int i = reports.size() - 1; i >= 0; i--) {
            JsonObject report = (JsonObject)reports.getValue( i );
            if (( (BigInteger)report.getValue( "units" ) ).intValue() != 0) {
                continue;
            }
            String path = (String)report.getValue( "path" );
            long value = ( (BigInteger)report.getValue( "amount" ) ).longValue();
            add( map, path, value );
        }
        return map;
    }

    public void dumpData( String prefix ) {
        for (String path : _data.keySet()) {
            System.out.println( prefix + path );
            System.out.println( _data.get( path ) );
        }
    }

    public static void main( String[] args ) throws Exception {
        new Dumper( new InputStreamReader( System.in ) ).dumpData( args[0] );
    }
}
