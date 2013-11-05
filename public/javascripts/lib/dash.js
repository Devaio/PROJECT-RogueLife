// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    var $charStats, $completed, $current, $dash, $game, $path, charSource, dashSource, handleChar, handleDash, handlePath, pathSource, updateDashboard;
    charSource = $('#char-stats').html();
    dashSource = $('#dash-board').html();
    pathSource = $('#path-chosen').html();
    handleChar = Handlebars.compile(charSource);
    handleDash = Handlebars.compile(dashSource);
    handlePath = Handlebars.compile(pathSource);
    $dash = $('#dashBoard');
    $completed = $('#completedQuests');
    $current = $('#currentQuests');
    $charStats = $('#charStats');
    $game = $('#gameAch');
    $current = $('#currentQuests');
    $path = $('#currentPath');
    updateDashboard = function(char) {
      $dash.html(handleDash(char));
      $charStats.html(handleChar(char));
      return $path.html(handlePath(char));
    };
    $.get('/charData', {}, function(userCharacter) {
      console.log(userCharacter);
      return updateDashboard(userCharacter);
    });
    $(document).on('click', '.choosePath', function() {
      $('#pathChooser').fadeOut();
      return $.get('/charData', {}, function(userCharacter) {
        return updateDashboard(userCharacter);
      });
    });
    $(document).on('click', '.addQuest', function() {
      $('.currentQuestList').append($('<p class="quest">Embark on a new quest!</p>'));
      return $('.quest').hallo({
        editable: true
      });
    });
    $(document).on('click', '.addDaily', function() {
      $('.dailyQuestList').append($('<p class="daily">Enter new Daily</p>'));
      return $('.daily').hallo({
        editable: true
      });
    });
    $(document).on('hallodeactivated', '.quest', function() {
      var quest;
      $(this).fadeOut('fast').fadeIn('fast');
      quest = $(this).text();
      return $.post('/addQuest', {
        currentQuest: quest
      }, function(data) {});
    });
    $(document).on('hallodeactivated', '.daily', function() {
      var daily;
      $(this).fadeOut('fast').fadeIn('fast');
      daily = $(this).text();
      return $.post('/addDaily', {
        daily: daily
      }, function(data) {});
    });
  });

}).call(this);
