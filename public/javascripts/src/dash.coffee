$ ->
	socket = io.connect()
	charSource =  $('#char-stats').html()
	dashSource = $('#dash-board').html()
	pathSource = $('#path-chosen').html()

	handleChar = Handlebars.compile(charSource)
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

	$dash = $('#dashBoard')
	$completed = $('#completedQuests')
	$current = $('#currentQuests')
	$charStats = $('#charStats')
	$game = $('#gameAch')
	$current = $('#currentQuests')
	$path = $('#currentPath')
	$('.questName').hallo({editable : true})
	$('.dailyName').hallo({editable : true})

	updateCharBars = (char) ->
		$('#experienceProgressbar').progressbar( {value : char.expPerc})
		$('#experienceProgressbar').find('.ui-progressbar-value').css( {'background' : '#660066'})
		$('#healthProgressbar').progressbar( {value : char.hpPerc})
		$('#healthProgressbar').find('.ui-progressbar-value').css( {'background' : '#F13939'})


	updateDashboard = (char) ->
		$dash.html handleDash char
		$charStats.html handleChar char
		$path.html handlePath char
		updateCharBars(char)

	checkOffQuest = (type, el) ->
		questDone = $(el).parent()
		questName = $(el).next().text()
		if type is 'quest'
			expGain = Math.floor(Math.random()*25 + 1)
		else
			expGain = Math.floor(Math.random()*60 + 1)
		console.log questName
		questDone.fadeOut('fast', () ->
			socket.emit 'finish' + type, { user : currentUser, questName : questName, expGain : expGain }) #this will remove the task from the database and give the user XP
	
	setInterval () ->
		questTimerUpdate()
	, 1000

	questTimerUpdate = () ->
		$('.quest').each () ->
			currTime = moment().format('X')
			# console.log 'c',currTime
			issueTime = $(@).find('.questTimer').attr('data-time')
			# console.log 'i',issueTime
			wait = currTime - issueTime
			# console.log 'w', wait
			waitConv = moment(issueTime*1000).fromNow()
			# console.log 'wc', waitConv
			$(@).find('.questTimer').text(waitConv)

	dailyTimer = (user) ->
		$('.daily').each () ->
			currTime = moment().format('X')
			console.log 'CURR', currTime
			issueTime = $(@).attr('data-time')
			console.log 'issueTime', issueTime
			wait = currTime - issueTime
			console.log 'WAIT', wait
			if wait > 30
				$(@).attr('data-time', moment().format('X'))
				hp = user.currentHealth - 20
				socket.emit 'damage', { user : user, HP : hp}
				


	$.get '/charData', {}, (userCharacter) ->
		console.log userCharacter
		updateDashboard(userCharacter)
		$('.questName').hallo({editable : true})
		$('.dailyName').hallo({editable : true})
		dailyTimer(userCharacter)
		window.currentUser = userCharacter # makes available for sockets
		


	$(document).on 'click', '.choosePath', () ->
		$('#pathChooser').fadeOut()
		$.get '/charData', {}, (userCharacter) ->
			updateDashboard(userCharacter)
			

	$(document).on 'click', '.addQuest', () ->
		$('.currentQuestList').append($('<li class="quest list-unstyled"><div class="questStatus"></div><span class="questName">Enter a new Quest</span><div class="questDelete pull-right">&times</div><div class="questTimer pull-right text-muted"></div></li>'))
		$('.questName').hallo({editable : true})
		

	$(document).on 'click', '.addDaily', () ->
		$('.dailyQuestList').append($('<li class="daily list-unstyled"><div class="dailyStatus"></div><span class="dailyName">Enter a new Daily</span><div class="dailyDelete pull-right">&times</div></li>'))
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
		checkOffQuest('Quest', @)

	$(document).on 'click', '.dailyStatus', () ->
		checkOffQuest('Daily', @)

	$(document).on 'mouseenter', '.quest, .daily', () ->
		# $(@).addClass('animated pulse')

	$(document).on 'mouseleave', '.quest, .daily', () ->
		# $(@).removeClass('animated pulse')

	$(document).on 'click', '.dailyDelete', () ->
		daily = $(@).prev().text()
		$.post '/removeDaily', {dailyName : daily}, () ->
			console.log currentUser
			updateDashboard currentUser

	$(document).on 'click', '.questDelete', () ->
		quest = $(@).prev().text()
		$.post '/removeQuest', {questName : quest}, () ->
			updateDashboard currentUser

	socket.on 'updateChar', (character) ->
		if character.level > currentUser.level
			$('#levelUp').fadeIn('slow', () ->
				$('#levelUp').addClass('animated flipOutX'))
			$('#experienceProgressbar').progressbar( {value : 0})
		console.log character
		updateDashboard(character)
		window.currentUser = character
		$('#experienceProgressbar').progressbar( {value : character.expPerc})
		$('#experienceProgressbar').find('.ui-progressbar-value').css( {'background' : '#660066'})
		$('#healthProgressbar').progressbar( {value : character.hpPerc})
		$('#healthProgressbar').find('.ui-progressbar-value').css( {'background' : '#F13939'})

	socket.on 'damageTaken', (character) ->
		if character.currentHealth <= 0
			socket.emit 'death', character


	return




