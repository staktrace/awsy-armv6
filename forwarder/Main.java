public class Main {
    public static void main(String[] args) {
        try {
            if ("-device".equals(args[0])) {
                DeviceForwarder df = new DeviceForwarder(Integer.parseInt(args[1]));
                df.run();
            } else if ("-host".equals(args[0])) {
                HostForwarder hf = new HostForwarder(Integer.parseInt(args[1]), Integer.parseInt(args[2]));
                hf.run();
            }
        } catch (Exception e) {
            System.out.println("Usage: dalvikvm Main -device <listenport>");
            System.out.println("Usage: java Main -host <forwardport> <num-content-ports>");
        }
    }
}
