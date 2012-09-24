import java.io.*;
import java.net.*;
import java.util.*;

public class DeviceForwarder extends BaseForwarder {
    private final int _port;
    private DataOutputStream _toHost;

    public DeviceForwarder(int port) {
        _port = port;
    }

    public void send(int port, int requestId, byte[] data, int len) throws IOException {
        sendTo(_toHost, port, requestId, data, len);
    }

    public void run() {
        Socket host = null;
        DataInputStream fromHost = null;
        DataOutputStream toHost = null;

        try {
            // the host-side forwarder instance has to initiate the connection
            ServerSocket socket = new ServerSocket(_port);

            while (true) {
                host = socket.accept();

                fromHost = new DataInputStream(host.getInputStream());
                toHost = new DataOutputStream(host.getOutputStream());

                // magic handshake
                toHost.writeInt(MAGIC);
                if (fromHost.readInt() == MAGIC) {
                    System.err.println("Handshake to host machine succeeded!");
                    break;
                }

                System.err.println("Handshake to host machine failed!");
                fromHost.close();
                toHost.close();
                host.close();
            }

            socket.close();
            _toHost = toHost;

            // read range of ports to forward
            int minPort = fromHost.readInt();
            int maxPort = fromHost.readInt();
            System.err.println("Spawning port servers on ports [" + minPort + ", " + maxPort + ")");
            List<PortServer> servers = new ArrayList<PortServer>();
            for (int i = minPort; i < maxPort; i++) {
                PortServer s = new PortServer(this, i);
                servers.add(s);
                s.start();
            }

            loop(fromHost, false);

            for (PortServer s : servers) {
                s.kill();
            }

            killConnections();
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                fromHost.close();
            } catch (Exception e) {
            }
            try {
                toHost.close();
            } catch (Exception e) {
            }
            try {
                host.close();
            } catch (Exception e) {
            }
        }
    }
}
