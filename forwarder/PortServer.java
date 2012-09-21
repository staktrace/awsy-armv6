import java.io.*;
import java.net.*;

class PortServer extends Thread {
    private final Forwarder _forwarder;
    private final int _port;

    private ServerSocket _socket;
    private boolean _die;

    PortServer(Forwarder forwarder, int port) {
        _forwarder = forwarder;
        _port = port;
    }

    public synchronized void kill() {
        _die = true;
        try {
            _socket.close();
        } catch (IOException ioe) {
        }
    }

    public void run() {
        try {
            _socket = new ServerSocket(_port);
            while (true) {
                synchronized (this) {
                    if (_die) {
                        break;
                    }
                }
                Socket client = _socket.accept();
                new ConnectionServer(_forwarder, _port, client).start();
            }
        } catch (IOException ioe) {
            synchronized (this) {
                if (_die) {
                    return;
                }
            }
            ioe.printStackTrace();
            try {
                _socket.close();
            } catch (IOException e) {
            }
        }
    }
}
