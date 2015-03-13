# LocationTracker
A sample iOS application that tracks the users location every X seconds when the app is in the background

Just run it, for sample purposes it only livetracks the user's location once it enters the background. The key of this working is that immediately after the app finished launching, it starts monitoring for significant location changes. Now, we don't do anything with the location updates that this method produces, it's there only so that the app will stay alive in the background and be able to respond to e.g. a remote notification telling the app to start live-tracking.
