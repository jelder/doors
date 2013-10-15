function Door(data) {
  this.state = data.state;
  this.timestamp = data.timestamp;
  this.name = data.name;
  this.host = data.host;
  this.sensor = data.sensor;
  this.path = 'doors/' + data.host + '/' + data.sensor + '.json';
  this.label = data.host + '-' + data.sensor;
}

var notify_is_possible = function() {
  if (window.hasOwnProperty('webkitNotifications')) {
    if (window.webkitNotifications.checkPermission() == 0) {
      return true;
    } else {
      window.webkitNotifications.requestPermission();
      return false;
    }
  } else {
    return false;
  }
}

var update = function(data,skip_notify) {
  var door = new Door(data);
  $row = $('#' + door.label);
  if (typeof door.state === "undefined") {
    $row.find('.status-box').addClass('offline');
  } else {
    $row.find('.status-box').removeClass('open closed offline').addClass(door.state);
    $row.find('.state').text(door.state);
    $row.find('.time').data("timestamp", door.timestamp).text(" since " + moment(door.timestamp).fromNow());
  }
  if (!skip_notify) { notify(door) }
};

var create = function(data,i) {
  var color = colors[i % colors.length];
  var door = new Door(data);
  if (typeof door.sensor === "undefined") {
    door.label = 'offline-' + i;
  }
  var $template = $('#template').clone();
  $template.find('.name').text(door.name);
  $template.attr("id", door.label).data('icon', icons[color]);
  if (notify_is_possible() && door.status != 'offline') {
    var $notify_pref = jQuery('<span/>')
      .addClass('notify-pref glyphicon glyphicon-heart-empty')
      .click(function() {
        var $elem = $(this);
         $elem.toggleClass("notify-enable")
           .toggleClass("glyphicon-heart-empty")
           .toggleClass("glyphicon-heart");
         if ($elem.hasClass("notify-enable")) {
           $.cookie(door.label+'-notify', true)
         } else {
           $.removeCookie(door.label+'-notify')
         }
      })
    if ($.cookie(door.label+'-notify')) { $notify_pref.click() }
    $template.find('.frame').prepend($notify_pref)
  }
  $('#doorlist').append($template);

  $.getJSON( door.path, function(data) {
    update(data,true);
    pusher.subscribe('change_events').bind(door.label, update);
  }).fail( function() {
    update(door,true);
  });
}

var notify = function(door) {
  if (typeof door.state === "undefined") { return }
  switch (door.state) {
    case "open":
      var message = "just opened!";
      break;
    case "closed":
      var message = "just closed :(";
      break;
  }
  if (row.find('.notify-enable').length == 1) {

    var notification = window.webkitNotifications.createNotification(
      row.data('icon'),row.find('.name').text(),
      message
    );

    notification.onclick = function () {
      notification.close();
    }
    notification.show();
  }
}

// Generate a set of icons for notifications from our color palette.
// Order must match .status-box:nth-of-type() declarations.
var color_data = {
  "#1564f9": "UVZPl4Z7ha",
  "#3fc41b": "U/xButvkTR",
  "#fa8e1f": "X6jh83IXPs",
  "#4ca8ea": "VMqOr4+3T5",
  "#f71347": "X3E0eeps0u",
  "#fcc124": "X8wST1RrWw"
};
var icons = [];
var colors = [];
$.each(color_data, function(color, magic){
  colors.push(color);
  icons[color] = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAIAAAACAAQMAAAD58POIAAAAA1BMVE"+magic+"AAAAGElEQVR4AWOgMxgFo2AUjIJRMApGwSgAAAiAAAH3bJXBAAAAAElFTkSuQmCC"
});

/* Load config, populate DOM and subscribe to Pusher events */
$.getJSON( "config.json", function( config ) {
  pusher = new Pusher(config.pusher);
  $.each( config.doors, function( i, data ) {
    create(data,i);
  });
});

// Update relative time presentation once per second.
(function(){
  $(".time").each(function(i){
    $(this).text(" since " + moment($(this).data("timestamp")).fromNow());
  });
  setTimeout(arguments.callee, 1000);
})();
