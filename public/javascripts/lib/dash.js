// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    var $avatar, $completed, $current, $dash, $game, $hpBar, $level, $path, $xpBar, avatarSource, dashSource, dashUpdater, handleAvatar, handleDash, handleLevel, handlePath, handlehp, handlexp, hpSource, levelSource, pathSource, socket, xpSource;
    socket = io.connect();
    dashSource = $('#dash-board').html();
    pathSource = $('#path-chosen').html();
    hpSource = $('#hp-stats').html();
    xpSource = $('#xp-stats').html();
    levelSource = $('#char-level').html();
    avatarSource = $('#avatar').html();
    handleAvatar = Handlebars.compile(avatarSource);
    handleLevel = Handlebars.compile(levelSource);
    handlehp = Handlebars.compile(hpSource);
    handlexp = Handlebars.compile(xpSource);
    handleDash = Handlebars.compile(dashSource);
    handlePath = Handlebars.compile(pathSource);
    Handlebars.registerHelper("each_upto", function(ary, max, options) {
      var i, result;
      if (!ary || ary.length === 0) {
        return options.inverse(this);
      }
      result = [];
      i = max;
      while (i > 0) {
        if (ary[i] !== void 0) {
          result.push(options.fn(ary[i]));
        }
        --i;
      }
      return result.join("");
    });
    $avatar = $('.charAvatar');
    $dash = $('#dashBoard');
    $completed = $('#completedQuests');
    $current = $('#currentQuests');
    $hpBar = $('.hpText');
    $xpBar = $('.xpText');
    $game = $('#gameAch');
    $current = $('#currentQuests');
    $path = $('#currentPath');
    $level = $('.levelIndicator');
    dashUpdater = (function() {
      var checkOffQuest, dailyTimer, questTimerUpdate, updateCharBars, updateDashboard;
      updateCharBars = function(char) {
        $('#experienceProgressbar').progressbar({
          value: char.expPerc
        });
        $('#experienceProgressbar').find('.ui-progressbar-value').css({
          'background': '#0972a5'
        });
        $('#healthProgressbar').progressbar({
          value: char.hpPerc
        });
        return $('#healthProgressbar').find('.ui-progressbar-value').css({
          'background': '#F13939'
        });
      };
      updateDashboard = function(char) {
        $dash.html(handleDash(char));
        $hpBar.html(handlehp(char));
        $xpBar.html(handlexp(char));
        $level.html(handleLevel(char));
        $avatar.html(handleAvatar(char));
        $path.html(handlePath(char));
        updateCharBars(char);
        return window.currentUser = char;
      };
      checkOffQuest = function(type, el) {
        var expGain, questDone, questName;
        questDone = $(el).parent();
        questName = $(el).next().text();
        if (type === 'Quest') {
          expGain = Math.floor(Math.random() * 25 + 10);
        } else {
          expGain = Math.floor(Math.random() * 60 + 30);
        }
        return questDone.fadeOut('fast', function() {
          return socket.emit('finish' + type, {
            user: currentUser,
            questName: questName,
            expGain: expGain
          });
        });
      };
      questTimerUpdate = function() {
        return $('.quest').each(function() {
          var currTime, issueTime, timeText, wait, waitConv;
          currTime = moment().format('X');
          issueTime = $(this).find('.questTimer').attr('data-time');
          wait = currTime - issueTime;
          waitConv = moment(issueTime * 1000).fromNow();
          return timeText = $(this).find('.questTimer').text(waitConv);
        });
      };
      dailyTimer = function(user) {
        $('.daily, .preDaily').each(function() {
          var currTime, issueTime, wait;
          window.timer = false;
          currTime = moment().format('X');
          issueTime = $(this).attr('data-time');
          wait = currTime - issueTime;
          if (wait > 1) {
            window.timer = true;
            return $(this).attr('data-time', moment().format('X'));
          }
        });
        if (timer) {
          socket.emit('damage', {
            user: user
          });
          return socket.emit('daily', {
            user: user
          });
        }
      };
      return {
        updateCharBars: updateCharBars,
        updateDashboard: updateDashboard,
        checkOffQuest: checkOffQuest,
        questTimerUpdate: questTimerUpdate,
        dailyTimer: dailyTimer
      };
    })();
    setTimeout(function() {
      $('.questName').hallo({
        editable: true
      });
      return $('.dailyName').hallo({
        editable: true
      });
    }, 1000);
    setInterval(function() {
      return dashUpdater.questTimerUpdate();
    }, 1000);
    $.get('/charData', {}, function(userCharacter) {
      console.log(userCharacter);
      dashUpdater.updateDashboard(userCharacter);
      dashUpdater.dailyTimer(userCharacter);
      return window.currentUser = userCharacter;
    });
    $(document).on('click', '.choosePath', function() {
      $('#pathChooser').fadeOut();
      return $.get('/charData', {}, function(userCharacter) {
        return dashUpdater.updateDashboard(userCharacter);
      });
    });
    $(document).on('click', '.addQuest', function() {
      $('.currentQuestList').append($('<li class="quest list-unstyled"><div class="questStatus"></div><span class="questName">Enter a new Quest</span><div class="questDelete pull-right">&times</div><div class="questTimer pull-right text-info"></div></li>').addClass('animated bounceInRight'));
      return $('.questName').hallo({
        editable: true
      });
    });
    $(document).on('click', '.addDaily', function() {
      $('.dailyQuestList').append($('<li class="daily list-unstyled"><div class="dailyStatus"></div><span class="dailyName">Enter a new Daily</span><div class="dailyDelete pull-right">&times</div></li>').addClass('animated bounceInLeft'));
      return $('.dailyName').hallo({
        editable: true
      });
    });
    $(document).on('halloactivated', '.questName', function() {
      var quest;
      quest = $(this).text();
      return $.post('/removeQuest', {
        questName: quest
      }, function() {});
    });
    $(document).on('hallodeactivated', '.questName', function() {
      var quest;
      $(this).fadeOut(100, function() {
        return $(this).fadeIn(100);
      });
      quest = $(this).text();
      return $.post('/updateQuest', {
        questName: quest
      }, function() {});
    });
    $(document).on('halloactivated', '.dailyName', function() {
      var daily;
      daily = $(this).text();
      return $.post('/removedaily', {
        dailyName: daily
      }, function() {});
    });
    $(document).on('hallodeactivated', '.dailyName', function() {
      var daily;
      $(this).fadeOut(100, function() {
        return $(this).fadeIn(100);
      });
      daily = $(this).text();
      return $.post('/updateDaily', {
        dailyName: daily
      }, function() {});
    });
    $(document).on('click', '.questStatus', function() {
      return dashUpdater.checkOffQuest('Quest', this);
    });
    $(document).on('click', '.dailyStatus', function() {
      return dashUpdater.checkOffQuest('Daily', this);
    });
    $(document).on('click', '.preDailyStatus', function() {
      dashUpdater.checkOffQuest('preDaily', this);
      return $('#dailyComplete').fadeIn();
    });
    $(document).on('click', '.dailyDelete', function() {
      var daily;
      daily = $(this).prev().text();
      $(this).parent().addClass('animated fadeOutLeft').fadeOut(1000);
      return $.post('/removeDaily', {
        dailyName: daily
      }, function() {});
    });
    $(document).on('click', '.questDelete', function() {
      var quest;
      quest = $(this).prev().text();
      $(this).parent().addClass('animated fadeOutRight').fadeOut(1000);
      return $.post('/removeQuest', {
        questName: quest
      }, function() {});
    });
    $(document).on('click', '.closeButton', function() {
      $('#death').addClass('animated fadeOutUp');
      return $('#dailyComplete').addClass('animated rollOut');
    });
    socket.on('updateChar', function(character) {
      if (character.level > currentUser.level) {
        $('#levelUp').fadeIn('slow', function() {
          return $('#levelUp').addClass('animated flipOutX');
        });
        $('#experienceProgressbar').progressbar({
          value: 0
        });
      }
      console.log(character);
      dashUpdater.updateDashboard(character);
      return $('#levelUp').removeClass('animated flipOutX');
    });
    socket.on('damageTaken', function(character) {
      dashUpdater.updateDashboard(character);
      if (character.currentHealth <= 0) {
        console.log('dmg', character);
        return socket.emit('death', character);
      }
    });
    socket.on('dead', function(character) {
      $('#death').removeClass('animated rollOut').fadeIn();
      return dashUpdater.updateDashboard(character);
    });
  });

}).call(this);
