// http://tanny.ica.com/ICA/TKO/test.nsf/js/addevent.js
// Accessed 8/08/08 for Red

// written by Dean Edwards, 2005
// with input from Tino Zijdel, Matthias Miller, Diego Perini
// http://dean.edwards.name/weblog/2005/10/add-event/
// 2007-07-10 TKO - Removed check for body in schedule because of problems with Firefox 2.0

/*global domReady */

function addEvent(element, type, handler) {
  // Modification by Tanny O'Haley, http://tanny.ica.com to add the
  // DOMContentLoaded for all browsers.
  if ((type === "DOMContentLoaded" || type === "domload")) {
    if(typeof domReady === "function") {
      domReady(handler);
      return;
    } else {
      type = "load";
    }
  }
  
  if (element.addEventListener) {
    element.addEventListener(type, handler, false);
  } else {
    // assign each event handler a unique ID
    if (!handler.$$guid) {
      handler.$$guid = addEvent.guid++;
    }
    // create a hash table of event types for the element
    if (!element.events) {
      element.events = {};
    }
    // create a hash table of event handlers for each element/event pair
    var handlers = element.events[type];
    if (!handlers) {
      handlers = element.events[type] = {};
      // store the existing event handler (if there is one)
      if (element["on" + type]) {
        handlers[0] = element["on" + type];
      }
    }
    // store the event handler in the hash table
    handlers[handler.$$guid] = handler;
    // assign a global event handler to do all the work
    element["on" + type] = handleEvent;
  }
}
// a counter used to create unique IDs
addEvent.guid = 1;

function removeEvent(element, type, handler) {
  if (element.removeEventListener) {
    element.removeEventListener(type, handler, false);
  } else {
    // delete the event handler from the hash table
    if (element.events && element.events[type]) {
      delete element.events[type][handler.$$guid];
    }
  }
}

function handleEvent(event) {
  var returnValue = true;
  // grab the event object (IE uses a global event object)
  event = event || fixEvent(((this.ownerDocument || this.document || this).parentWindow || window).event);
  // get a reference to the hash table of event handlers
  var handlers = this.events[event.type];
  // execute each event handler
  for (var i in handlers) {
    this.$$handleEvent = handlers[i];
    if (this.$$handleEvent(event) === false) {
      returnValue = false;
    }
  }
  return returnValue;
}

function fixEvent(event) {
  // add W3C standard event methods
  event.preventDefault = fixEvent.preventDefault;
  event.stopPropagation = fixEvent.stopPropagation;
  return event;
}
fixEvent.preventDefault = function() {
  this.returnValue = false;
};
fixEvent.stopPropagation = function() {
  this.cancelBubble = true;
};

// End Dean Edwards addEvent.

// Tino Zijdel - crisp@xs4all.nl This little snippet fixes the problem that the onload attribute on 
// the body-element will overwrite previous attached events on the window object for the onload event.
if (!window.addEventListener) {
  document.onreadystatechange = function(){
    if (window.onload && window.onload !== handleEvent) {
      addEvent(window, 'load', window.onload);
      window.onload = handleEvent;
    }
  };
}

// -----------------------------------------------------
// -----------------------------------------------------

// http://tanny.ica.com/ICA/TKO/test.nsf/js/domready.js
// Accessed 8/08/08 for Red

// DOMContentLoaded event handler. Works for browsers that don't support the DOMContentLoaded event.
//
// Modification Log:
// Date   Initial Description
// 26 May 2008  TKO Created by Tanny O'Haley

/*global addEvent, escape, unescape */

var domReadyEvent = {
  name: "domReadyEvent",
  // Array of DOMContentLoaded event handlers.
  events: {},
  domReadyID: 1,
  bDone: false,
  DOMContentLoadedCustom: null,
  
  // Function that adds DOMContentLoaded listeners to the array.
  add: function(handler) {
    // Assign each event handler a unique ID. If the handler has an ID, it
    // has already been added to the events object or been run.
    if (!handler.$$domReadyID) {
      handler.$$domReadyID = this.domReadyID++;
      
      // If the DOMContentLoaded event has happened, run the function.
      if(this.bDone){
        handler();
      }
      
      // store the event handler in the hash table
      this.events[handler.$$domReadyID] = handler;
    }
  },
  
  remove: function(handler) {
    // Delete the event handler from the hash table
    if (handler.$$domReadyID) {
      delete this.events[handler.$$domReadyID];
    }
  },
  
  // Function to process the DOMContentLoaded events array.
  run: function() {
    // quit if this function has already been called
    if (this.bDone) {
      return;
    }
    
    // Flag this function so we don't do the same thing twice
    this.bDone = true;
    
    // iterates through array of registered functions 
    for (var i in this.events) {
      this.events[i]();
    }
  },
  
  schedule: function() {
    // Quit if the init function has already been called
    if (this.bDone) {
      return;
    }
    
    // First, check for Safari or KHTML.
    if(/KHTML|WebKit/i.test(navigator.userAgent)) {
      if(/loaded|complete/.test(document.readyState)) {
        this.run();
      } else {
        // Not ready yet, wait a little more.
        setTimeout(this.name + ".schedule()", 100);
      }
    } else if(document.getElementById("__ie_onload")) {
      // Second, check for IE.
      return true;
    }
    
    // Check for custom developer provided function.
    if(typeof this.DOMContentLoadedCustom === "function") {
      //if DOM methods are supported, and the body element exists
      //(using a double-check including document.body, for the benefit of older moz builds [eg ns7.1] 
      //in which getElementsByTagName('body')[0] is undefined, unless this script is in the body section)
      if(typeof document.getElementsByTagName !== 'undefined' && (document.getElementsByTagName('body')[0] !== null || document.body !== null)) {
        // Call custom function.
        if(this.DOMContentLoadedCustom()) {
          this.run();
        } else {
          // Not ready yet, wait a little more.
          setTimeout(this.name + ".schedule()", 250);
        }
      }
    }
    
    return true;
  },
  
  init: function() {
    // If addEventListener supports the DOMContentLoaded event.
    if(document.addEventListener) {
      document.addEventListener("DOMContentLoaded", function() { domReadyEvent.run(); }, false);
    }
    
    // Schedule to run the init function.
    setTimeout("domReadyEvent.schedule()", 100);
    
    function run() {
      domReadyEvent.run();
    }
    
    // Just in case window.onload happens first, add it to onload using an available method.
    if(typeof addEvent !== "undefined") {
      addEvent(window, "load", run);
    } else if(document.addEventListener) {
      document.addEventListener("load", run, false);
    } else if(typeof window.onload === "function") {
      var oldonload = window.onload;
      window.onload = function() {
        domReadyEvent.run();
        oldonload();
      };
    } else {
      window.onload = run;
    }
    
    /* for Internet Explorer */
    /*@cc_on
      @if (@_win32 || @_win64)
      document.write("<script id=__ie_onload defer src=\"//:\"><\/script>");
      var script = document.getElementById("__ie_onload");
      script.onreadystatechange = function() {
        if (this.readyState == "complete") {
          domReadyEvent.run(); // call the onload handler
        }
      };
      @end
    @*/
  }
};

var domReady = function(handler) { domReadyEvent.add(handler); };
domReadyEvent.init();