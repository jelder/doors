# Doors

This project aims to solve the problem of people walking half way across the office only to find a room they want to use is occupied, then either waiting in line or returning to their desk.

The solution is a minimal web page which can be consulted anonymously before making the trek. Think of it as *event-driven IO for physical spaces*.

## User Experience

![Desktop Screenshot](https://raw.github.com/jelder/doors/master/screenshots/desktop_screenshot.png "Desktop Screenshot")

The app is designed to be used transiently and anonymously.

Each doors' status, open or closed and for approximately how long, is updated in real time for desktop and mobile browsers.

If using a compatible web browser (Safari, Chrome, and possibly others), a checkbox will appear next to each door. Checking this box will cause a desktop notification to appear whenever the door is open. These work as long the site is open in a tab, even if the browser window is hidden. This preference will be remembered until the users' next visit.

### Desktop Notifications

If you're using Safari, desktop notifications should work out of the box. Chrome may require you to first visit `chrome://flags` and enable "Rich Notifications," then `chrome://settings/content` and select either "Allow all sites to show desktop notifications" or "Ask me when a site wants to show desktop notifications (recommended)."

### Privacy

The site stores a single cookie for each checkbox. We plan to move the site to SSL in the near future. It does not use Google Analytics or any other tracking software.

## Behind the Scenes

The project relies on a hardware platform consisting of a microcontroller ([Digispark](http://digistump.com/products/1) running our Arduino code) connected to a pair of magnetic reed switches (of the type used in security systems), which is in turn connected to via USB to a computer running the Door Agent (ruby). The Door Agent is responsible for announcing changes in doors' states in real time to website visitors.

![Mark 1](https://raw.github.com/jelder/doors/master/screenshots/hardware.jpg "Mark 1")

At [Boundless](https://www.boundless.com/), one of these devices is installed in the server room and is responsible for the Gutenberg conference room's door. Another is connected to the Mac mini behind the dashboard screen by the engineering team's couches and is responsible for both bathrooms.

The app is a static site hosted on Amazon S3.

## Bugs

* We're still susceptible to the [thundering herd problem](http://en.wikipedia.org/wiki/Thundering_herd_problem).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
