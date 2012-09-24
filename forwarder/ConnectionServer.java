import java.io.*;
import java.net.*;

class ConnectionServer extends Thread {
    private final Forwarder _forwarder;
    private final int _port;
    private final int _requestId;
    private final Socket _conn;
    private InputStream _in;
    private OutputStream _out;

    ConnectionServer(Forwarder forwarder, int port, Socket conn) throws IOException {
        setDaemon(true);

        _forwarder = forwarder;
        _port = port;
        _requestId = conn.getPort();
        conn.setTcpNoDelay(true);
        _conn = conn;
        _in = _conn.getInputStream();
        _out = _conn.getOutputStream();

        _forwarder.addConnection(this);
    }

    ConnectionServer(Forwarder forwarder, int port, int requestId) throws IOException {
        setDaemon(true);

        _forwarder = forwarder;
        _port = port;
        _requestId = requestId;
        _conn = new Socket(InetAddress.getByName("localhost"), _port);
        _conn.setTcpNoDelay(true);
        _out = _conn.getOutputStream();
        _in = _conn.getInputStream();

        _forwarder.addConnection(this);
    }

    int getRequestId() {
        return _requestId;
    }

    void fromForwarder(byte[] data, int len) {
        if (data != null) {
            try {
                _out.write(data, 0, len);
                return;
            } catch (IOException ioe) {
                System.err.println(toString() + " errored out attempting to write " + len + " bytes");
                if (_in != null) {
                    dump(ioe);
                }
            }
        }

        _out = null;

        System.err.println(toString() + " shutting down output...");
        try {
            _conn.shutdownOutput();
        } catch (IOException ioe) {
            if (_in != null) {
                dump(ioe);
            }
        }

        checkClose();
    }

    private synchronized void checkClose() {
        if (_in == null && _out == null) {
            try {
                _conn.close();
            } catch (IOException e) {
            }
            _forwarder.removeConnection(this);
        }
    }

    public void run() {
        boolean inputReset = false;
        byte[] buf = new byte[Forwarder.MAX_BLOCK_SIZE];
        try {
            while (true) {
                int len = _in.read(buf);
                if (len < 0) {
                    break;
                }
                _forwarder.send(_port, _requestId, buf, len);
            }
        } catch (SocketException se) {
            if (se.getMessage().indexOf("ECONNRESET") >= 0) {
                inputReset = true;
            } else {
                dump(se);
            }
        } catch (IOException ioe) {
            dump(ioe);
        }

        _in = null;

        System.err.println(toString() + " shutting down input...");

        try {
            _conn.shutdownInput();
        } catch (IOException ioe) {
            if (_out != null && !inputReset) {
                dump(ioe);
            }
        }

        try {
            _forwarder.send(_port, _requestId, null, -1);
        } catch (IOException ioe) {
            dump(ioe);
        }

        checkClose();
    }

    private void dump(Exception e) {
        System.err.println("Exception in " + toString());
        e.printStackTrace();
    }

    @Override public String toString() {
        return "ConnectionServer [req=" + _requestId + "; port=" + _port + "]";
    }
}
