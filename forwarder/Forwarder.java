import java.io.IOException;

public interface Forwarder {
    public static final int MAGIC = 0x20120921;
    public static final int MAX_BLOCK_SIZE = 8192;

    public void send(int port, int requestId, byte[] data, int len) throws IOException;
    public void addConnection(ConnectionServer conn);
    public void removeConnection(ConnectionServer conn);
}
