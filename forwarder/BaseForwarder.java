import java.io.*;
import java.net.*;
import java.util.*;

public abstract class BaseForwarder implements Runnable, Forwarder {
    private final Map<Integer, ConnectionServer> _connections;

    public BaseForwarder() {
        _connections = new HashMap<Integer, ConnectionServer>();
    }

    protected final void sendTo(DataOutputStream out, int port, int requestId, byte[] data, int len) throws IOException {
        synchronized (out) {
            out.writeInt(port);
            out.writeInt(requestId);
            if (data == null) {
                out.writeInt(-1);
            } else {
                out.writeInt(len);
                out.write(data, 0, len);
            }
        }
    }

    public final void addConnection(ConnectionServer conn) {
        synchronized (_connections) {
            _connections.put(conn.getRequestId(), conn);
        }
        System.err.println("Adding connection: " + conn);
    }

    public final void removeConnection(ConnectionServer conn) {
        synchronized (_connections) {
            _connections.remove(conn.getRequestId());
        }
        System.err.println("Removing connection: " + conn);
    }

    protected final void killConnections() {
        List<ConnectionServer> conns = new ArrayList<ConnectionServer>();
        synchronized (_connections) {
            conns.addAll(_connections.values());
        }
        for (ConnectionServer conn : conns) {
            conn.fromForwarder(null, -1);
        }
    }

    protected final void loop(DataInputStream in, boolean createOnDemand) throws IOException {
        byte[] buf = new byte[MAX_BLOCK_SIZE];

        while (true) {
            int port;
            try {
                port = in.readInt();
            } catch (EOFException e) {
                System.err.println("Main incoming stream terminated; shutting down...");
                break;
            }
            int requestId = in.readInt();
            int len = in.readInt();
            if (len > 0) {
                in.readFully(buf, 0, len);
            }

            ConnectionServer conn;
            synchronized (_connections) {
                conn = _connections.get(requestId);
                if (conn == null) {
                    if (! createOnDemand) {
                        System.err.println("Unexpected request id: " + requestId + "; incoming data of length " + len);
                        continue;
                    }
                    conn = new ConnectionServer(this, port, requestId);
                    conn.start();
                }
            }
            if (len < 0) {
                conn.fromForwarder(null, -1);
            } else if (len > 0) {
                conn.fromForwarder(buf, len);
            }
        }
    }
}
