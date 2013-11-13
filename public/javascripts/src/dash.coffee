$ ->
	socket = io.connect()
	dashSource = $('#dash-board').html()
	pathSource = $('#path-chosen').html()
	hpSource =  $('#hp-stats').html()
	xpSource =  $('#xp-stats').html()
	levelSource = $('#char-level').html()
	avatarSource = $('#avatar').html()
	handleAvatar = Handlebars.compile(avatarSource)
	handleLevel = Handlebars.compile(levelSource)
	handlehp = Handlebars.compile(hpSource)
	handlexp = Handlebars.compile(xpSource)
	handleDash = Handlebars.compile(dashSource)
	handlePath = Handlebars.compile(pathSource)
	Handlebars.registerHelper "each_upto", (ary, max, options) ->
		return options.inverse(this)  if not ary or ary.length is 0
		result = []
		i = max

		while i > 0
			if ary[i] isnt undefined
				result.push options.fn(ary[i])
			--i
		result.join ""
	$avatar = $('.charAvatar')
	$dash = $('#dashBoard')
	$completed = $('#completedQuests')
	$current = $('#currentQuests')
	$hpBar = $('.hpText')
	$xpBar = $('.xpText')
	$game = $('#gameAch')
	$current = $('#currentQuests')
	$path = $('#currentPath')
	$level = $('.levelIndicator')
	


	dashUpdater = (() ->

		updateCharBars = (char) ->
			$('#experienceProgressbar').progressbar( {value : char.expPerc})
			$('#experienceProgressbar').find('.ui-progressbar-value').css( {'background' : '#0972a5'})
			$('#healthProgressbar').progressbar( {value : char.hpPerc})
			$('#healthProgressbar').find('.ui-progressbar-value').css( {'background' : '#F13939'})


		updateDashboard = (char) ->
			$dash.html handleDash char
			$hpBar.html handlehp char
			$xpBar.html handlexp char
			$level.html handleLevel char
			$avatar.html handleAvatar char
			$path.html handlePath char
			updateCharBars(char)
			window.currentUser = char

		checkOffQuest = (type, el) ->
			questDone = $(el).parent()
			questName = $(el).next().text()
			if type is 'Quest'
				expGain = Math.floor(Math.random()*25 + 10)
			else
				expGain = Math.floor(Math.random()*60 + 30)
			questDone.fadeOut('fast', () ->
				socket.emit 'finish' + type, { user : currentUser, questName : questName, expGain : expGain }) #this will remove the task from the database and give the user XP

		questTimerUpdate = () ->
			$('.quest').each () ->
				currTime = moment().format('X')
				issueTime = $(@).find('.questTimer').attr('data-time')
				wait = currTime - issueTime
				waitConv = moment(issueTime*1000).fromNow()
				timeText = $(@).find('.questTimer').text(waitConv)
				

		dailyTimer = (user) ->
			$('.daily, .preDaily').each () ->
				window.timer = false
				currTime = moment().format('X')
				issueTime = $(@).attr('data-time')
				wait = currTime - issueTime
				if wait > 1
					window.timer = true
					$(@).attr('data-time', moment().format('X'))
			if timer
				socket.emit 'damage', { user : user}
				socket.emit 'daily', {user : user}


	
		updateCharBars : updateCharBars,
		updateDashboard : updateDashboard,
		checkOffQuest : checkOffQuest,
		questTimerUpdate : questTimerUpdate,
		dailyTimer : dailyTimer
		
		
		)()
	setTimeout () ->
		$('.questName').hallo({editable : true})
		$('.dailyName').hallo({editable : true})
	, 1000
	setInterval () ->
		dashUpdater.questTimerUpdate()
	, 1000

	$.get '/charData', {}, (userCharacter) ->
		console.log userCharacter
		dashUpdater.updateDashboard(userCharacter)
		dashUpdater.dailyTimer(userCharacter)
		window.currentUser = userCharacter # makes available for sockets


		


	$(document).on 'click', '.choosePath', () ->
		$('#pathChooser').fadeOut()
		$.get '/charData', {}, (userCharacter) ->
			dashUpdater.updateDashboard(userCharacter)
			
	#adding quests/dailies from button
	$(document).on 'click', '.addQuest', () ->
		$('.currentQuestList').append($('<li class="quest list-unstyled"><div class="questStatus"></div><span class="questName">Enter a new Quest</span><div class="questDelete pull-right">&times</div><div class="questTimer pull-right text-info"></div></li>').addClass('animated bounceInRight'))
		$('.questName').hallo({editable : true})
		

	$(document).on 'click', '.addDaily', () ->
		$('.dailyQuestList').append($('<li class="daily list-unstyled"><div class="dailyStatus"></div><span class="dailyName">Enter a new Daily</span><div class="dailyDelete pull-right">&times</div></li>').addClass('animated bounceInLeft'))
		$('.dailyName').hallo({editable : true})

	#editing quests - remove and re-adds them as name changes
	$(document).on 'halloactivated', '.questName', () ->
		quest = $(@).text()
		$.post '/removeQuest', {questName : quest}, () ->
	
	$(document).on 'hallodeactivated', '.questName', () ->
		$(@).fadeOut(100, () ->
			$(@).fadeIn(100))
		quest = $(@).text()
		$.post '/updateQuest', {questName : quest}, () ->

	$(document).on 'halloactivated', '.dailyName', () ->
		daily = $(@).text()
		$.post '/removedaily', {dailyName : daily}, () ->

	$(document).on 'hallodeactivated', '.dailyName', () ->
		$(@).fadeOut(100, () ->
			$(@).fadeIn(100))
		daily = $(@).text()
		$.post '/updateDaily', {dailyName : daily}, () ->
		
	# Completing quests
	$(document).on 'click', '.questStatus', () ->
		dashUpdater.checkOffQuest('Quest', @)

	$(document).on 'click', '.dailyStatus', () ->
		dashUpdater.checkOffQuest('Daily', @)

	$(document).on 'click', '.preDailyStatus', () ->
		dashUpdater.checkOffQuest('preDaily', @)
		$('#dailyComplete').fadeIn()

	$(document).on 'click', '.dailyDelete', () ->
		daily = $(@).prev().text()
		$(@).parent().addClass('animated fadeOutLeft').fadeOut(1000)
		$.post '/removeDaily', {dailyName : daily}, () ->
		
	$(document).on 'click', '.questDelete', () ->
		quest = $(@).prev().text()
		$(@).parent().addClass('animated fadeOutRight').fadeOut(1000)
		$.post '/removeQuest', {questName : quest}, () ->

	$(document).on 'click', '.closeButton', () ->
		$('#death').addClass('animated fadeOutUp')
		$('#dailyComplete').addClass('animated rollOut')

	socket.on 'updateChar', (character) ->
		if character.level > currentUser.level
			$('#levelUp').fadeIn('slow', () ->
				$('#levelUp').addClass('animated flipOutX'))
			$('#experienceProgressbar').progressbar( {value : 0})
		console.log character
		dashUpdater.updateDashboard(character)
		$('#levelUp').removeClass('animated flipOutX')
		

	socket.on 'damageTaken', (character) ->
		dashUpdater.updateDashboard(character)
		if character.currentHealth <= 0
			console.log 'dmg', character
			socket.emit 'death', character

	socket.on 'dead', (character) ->
		$('#death').removeClass('animated rollOut').fadeIn()
		dashUpdater.updateDashboard(character)
		

	return




