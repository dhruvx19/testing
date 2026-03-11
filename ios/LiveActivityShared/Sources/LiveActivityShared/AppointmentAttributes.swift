import ActivityKit

@available(iOS 16.1, *)
public struct AppointmentAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var doctorName: String
        public var timeInfo: String
        public var expectedTime: String
        public var currentToken: Int
        public var userToken: Int
        public var hospitalName: String

        public init(doctorName: String, timeInfo: String, expectedTime: String, currentToken: Int, userToken: Int, hospitalName: String) {
            self.doctorName = doctorName
            self.timeInfo = timeInfo
            self.expectedTime = expectedTime
            self.currentToken = currentToken
            self.userToken = userToken
            self.hospitalName = hospitalName
        }
    }

    public var appointmentId: String

    public init(appointmentId: String) {
        self.appointmentId = appointmentId
    }
}
