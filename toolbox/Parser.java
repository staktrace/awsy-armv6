import java.math.BigInteger;
import java.util.Map;
import java.util.TreeMap;

import com.staktrace.util.conv.json.JsonArray;
import com.staktrace.util.conv.json.JsonObject;

public class Parser {
    public static Map<String, Long> toMap( JsonObject memDump ) {
        Map<String, Long> map = new TreeMap<String, Long>();
        JsonArray reports = (JsonArray)memDump.getValue( "reports" );
        for (int i = reports.size() - 1; i >= 0; i--) {
            JsonObject report = (JsonObject)reports.getValue( i );
            if (( (BigInteger)report.getValue( "units" ) ).intValue() != 0) {
                continue;
            }
            String path = sanitize( (String)report.getValue( "path" ) );
            long value = ( (BigInteger)report.getValue( "amount" ) ).longValue();
            add( map, path, value );
            while (path.lastIndexOf( '/' ) >= 0) {
                path = path.substring( 0, path.lastIndexOf( '/' ) );
                add( map, path, value );
            }
        }
        return map;
    }

    private static void add( Map<String, Long> map, String path, long value ) {
        Long old = map.get( path );
        if (old == null) {
            map.put( path, value );
        } else {
            map.put( path, value + old );
        }
    }

    private static String sanitize( String path ) {
        return path.replaceAll( "0x\\p{XDigit}+", "0xSTRIPPED" )
                   .replaceAll( "zone\\(\\p{XDigit}+\\)", "zone(STRIPPED)" )
                   .replaceAll( "\\{\\p{XDigit}{8}-\\p{XDigit}{4}-\\p{XDigit}{4}-\\p{XDigit}{4}-\\p{XDigit}{12}\\}", "UUID-STRIPPED" )
                   .replaceAll( "blob:\\p{XDigit}{8}-\\p{XDigit}{4}-\\p{XDigit}{4}-\\p{XDigit}{4}-\\p{XDigit}{12}", "blob:UUID-STRIPPED" )
                   .replaceAll( "id=\\p{Digit}+", "id=STRIPPED" )
                   .replaceAll( ".jsm:\\p{Digit}+", ".jsm:LINE-STRIPPED" );
    }
}
