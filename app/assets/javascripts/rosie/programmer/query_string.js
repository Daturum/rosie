var QueryString = function (query) {
  // This function is anonymous, is executed immediately and
  // the return value is assigned to QueryString!

  if(!query) query  = window.location.search;
  if(query[0] == '?') query = query.substring(1);

  window.query_strings || (window.query_strings = {})
  if(window.query_strings[query]) return window.query_strings[query];
  
  var query_string = {};
  var vars = query.split("&");
  for (var i=0;i<vars.length;i++) {
    var pair = vars[i].split("=");
    pair[1] = pair[1].replace(/\+/g, '%20');
        // If first entry with this name
    if (typeof query_string[pair[0]] === "undefined") {
      query_string[pair[0]] = decodeURIComponent(pair[1]);
        // If second entry with this name
    } else if (typeof query_string[pair[0]] === "string") {
      var arr = [ query_string[pair[0]],decodeURIComponent(pair[1]) ];
      query_string[pair[0]] = arr;
        // If third or later entry with this name
    } else {
      query_string[pair[0]].push(decodeURIComponent(pair[1]));
    }
  }
  query_string['build'] = function(){
    var qs = this, result = [];
    Object.keys(qs).forEach(function(key,index) {
      if(key != 'build') 
        result.push(encodeURIComponent(key) + '=' + encodeURIComponent(qs[key]));
    });
    return result.join('&');
  }.bind(query_string);
  
  window.query_strings[query] = query_string;
  
  return query_string;
};
