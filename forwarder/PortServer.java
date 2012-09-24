import java.io.*;
import java.net.*;

class PortServer extends Thread {
    private final Forwarder _forwarder;
    private final int _port;

    private ServerSocket _socket;
    private boolean _die;

    PortServer(Forwarder forwarder, int port) {
        setDaemon(true);

        _forwarder = forwarder;
        _port = port;
    }

    public synchronized void kill() {
        _die = true;
        close();
    }

    private synchronized boolean dead() {
        return _die;
    }

    private void close() {
        try {
            _socket.close();
        } catch (IOException ioe) {
        }
    }

    public void run() {
        try {
            _socket = new ServerSocket(_port);
            while (! dead()) {
                Socket client = _socket.accept();
                new ConnectionServer(_forwarder, _port, client).start();
            }
        } catch (IOException ioe) {
            if (! dead()) {
                ioe.printStackTrace();
                close();
            }
        }
    }
}
