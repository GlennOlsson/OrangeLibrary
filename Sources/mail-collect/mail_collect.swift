@main
public struct mail_collect {
    public private(set) var text = "Hello, World!"

    public static func main() {
        print(mail_collect().text)
    }
}
