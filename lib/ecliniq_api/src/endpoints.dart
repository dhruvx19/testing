class Endpoints {
  static const String localhost = 'https://api.upcharq.com';
  static const String prod = '';

  static String get websocketBaseUrl => localhost.replaceAll('/api', '');

  static String get loginOrRegisterUser =>
      '$localhost/api/auth/login-or-register';

  static String get verifyUser => '$localhost/api/auth/verify-user';

  static String get login => '$localhost/api/auth/login';

  static String get getUrl => '$localhost/api/storage/upload-url';
  static String get storageDownloadUrl => '$localhost/api/storage/download-url';
  static String get storagePublicUrl => '$localhost/api/storage/public-url';

  static String get patientDetails =>
      '$localhost/api/patients/create-patient-profile';
  static String get updatePatientProfile =>
      '$localhost/api/patients/update-profile';
  static String get topHospitals => '$localhost/api/hospitals/top-hospitals';
  static String get getAllHospitals => '$localhost/api/hospitals/getAllHospitals';
  static String get topDoctors => '$localhost/api/doctors/top-doctors';
  static String get filteredDoctors => '$localhost/api/doctors/filteredDoctors';
  static String hospitalDetails(String hospitalId) =>
      '$localhost/api/hospitals/getHospitalDetailsByIdbyPatient/$hospitalId';
  static String getAllDoctorHospital(String hospitalId) =>
      '$localhost/api/doctors/getAllDoctorsByHospitalIdForPatient/$hospitalId';
  static String get getSlotsByDate => '$localhost/api/slots/patient/find-slots';
  static String get findWeeklySlots =>
      '$localhost/api/slots/patient/find-weekly-slots';
  static String get holdToken => '$localhost/api/slots/patient/hold-token';
  static String get bookAppointment => '$localhost/api/appointments/book';
  static String get scheduledAppointments =>
      '$localhost/api/appointments/scheduledAppointments';
  static String get appointmentHistory =>
      '$localhost/api/appointments/appointmentHistory';
  static String appointmentDetail(String appointmentId) =>
      '$localhost/api/appointments/appointment/$appointmentId';
  static String cancelAppointment(String appointmentId) =>
      '$localhost/api/appointments/cancel/$appointmentId';
  static String get rescheduleAppointment =>
      '$localhost/api/appointments/reschedule';
  static String get verifyAppointment => '$localhost/api/appointments/verify';
  static String rateAppointment(String appointmentId) =>
      '$localhost/api/appointments/rate/$appointmentId';
  static String get getPatientDetails =>
      '$localhost/api/patients/get-patient-details';
  static String get addDependent => '$localhost/api/patients/add-dependent';
  static String get getDependents => '$localhost/api/patients/get-dependents';
  static String get getFavouriteDoctors =>
      '$localhost/api/patients/get-favourite-doctors';
  static String doctorDetailsById(String doctorId) =>
      '$localhost/api/doctors/doctorDetailsByIdByPatient/$doctorId';
  static String doctorDetailsForBooking(String doctorId) =>
      '$localhost/api/doctors/doctorDetailsForBooking/$doctorId';

  static String addFavouriteDoctor(String doctorId) =>
      '$localhost/api/patients/add-favourite-doctor/$doctorId';
  static String removeFavouriteDoctor(String doctorId) =>
      '$localhost/api/patients/remove-favourite-doctor/$doctorId';

  static String get registerDeviceToken =>
      '$localhost/api/device-tokens/register';

  // Change contact endpoints (4-step flow)
  static String get sendExistingContactOTP =>
      '$localhost/api/auth/change-contact/send-existing-otp';
  static String get verifyExistingContactOtp =>
      '$localhost/api/auth/change-contact/verify-existing-otp';
  static String get sendNewContactOtp =>
      '$localhost/api/auth/change-contact/send-new-otp';
  static String get verifyNewContactOtp =>
      '$localhost/api/auth/change-contact/verify-new-otp';

  static String paymentStatus(String merchantTxnId) =>
      '$localhost/api/payments/status/$merchantTxnId';
  static String paymentDetails(String appointmentId) =>
      '$localhost/api/payments/appointment/$appointmentId';

  // Forget MPIN endpoints (3-step flow)
  static String get forgetMpinSendOtp =>
      '$localhost/api/auth/forget-mpin/send-otp';
  static String get forgetMpinVerifyOtp =>
      '$localhost/api/auth/forget-mpin/verify-otp';
  static String get forgetMpinReset => '$localhost/api/auth/forget-mpin/reset';

  // Patient notification preferences
  static String get updateNotificationPreferences =>
      '$localhost/api/patients/update-notification-preferences';
}
