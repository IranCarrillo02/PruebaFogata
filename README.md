# PruebaFogata

The application was developed for geolocation using the native map provided by iOS. The following functionalities were integrated into the app:

1. Create new pins through long taps on the screen.
2. Add a custom name to each pin.
3. View information for each pin (coordinates and name).
4. Request permissions for geolocation usage and access the user's current location.

Additionally, the ability to persist pin data in the device's internal storage was added using CoreData. This allows the creation and deletion of pins according to user preferences.

On the technical side, I opted for an MVVM architecture since the flow of information between layers is not highly intense. The graphical interface was also developed programmatically to improve the app's performance.

For the use of this application, the integration of any external libraries or dependencies is not necessary, as everything was built using native iOS elements.
