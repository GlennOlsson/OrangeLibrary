import Foundation

import Logging 

@main
public struct mail_collect {
    public private(set) var text = "Hello, World!"

    public static func main() {
        let app = createApp()

        defer { 
            print("Shutting down...")
            app.shutdown() 
        }

        DispatchQueue.global(priority: .background).async {
            try! app.run()
        }

        // print(mail_collect().text)

        // let semaphore = DispatchSemaphore(value: 0)

        // Task { @MainActor in 
        //     defer { 
        //         print("Signaling semahpore")
        //         semaphore.signal() 

        //     }
        //     let config = try await Config()

        //     print("Making query")
        //     // guard let result = config.database?.connection.query("SELECT emails FROM subscribers") else {
        //     //     print("No results")
        //     //     return
        //     // }

        //     // print("Made query, getting")

        //     // let rows = try await result.get()

        //     // print("Got query")

        //     // for row in rows {
        //     //     print("ROW", row)
        //     // }
                
        //     // await config.killDatabase()
        // }

        // semaphore.wait()
        // print("exiting")
    }
}
