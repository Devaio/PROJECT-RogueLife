$ ->
	socket = io.connect()
	charSource =  $('#char-stats').html()
	dashSource = $('#dash-board').html()
	pathSource = $('#path-chosen').html()

	handleChar = Handlebars.compile(charSource)
	handleDash = Handlebars.compile(dashSource)
	handlePath = Handlebars.compile(pathSource)



	$dash = $('#dashBoard')
	$completed = $('#completedQuests')
	$current = $('#currentQuests')
	$charStats = $('#charStats')
	$game = $('#gameAch')
	$current = $('#currentQuests')
	$path = $('#currentPath')
	$('.questName').hallo({editable : true})
	$('.dailyName').hallo({editable : true})

	updateDashboard = (char) ->
		$dash.html handleDash char
		$charStats.html handleChar char
		$path.html handlePath char

	$.get '/charData', {}, (userCharacter) ->
		console.log userCharacter
		updateDashboard(userCharacter)
		$('.questName').hallo({editable : true})
		$('.dailyName').hallo({editable : true})
		window.currentUser = userCharacter
		console.log 'CURRENT', currentUser


	$(document).on 'click', '.choosePath', () ->
		$('#pathChooser').fadeOut()
		$.get '/charData', {}, (userCharacter) ->
			updateDashboard(userCharacter)
			

	$(document).on 'click', '.addQuest', () ->
		$('.currentQuestList').append($('<li class="quest list-unstyled"><div class="questStatus"></div><span class="questName">Enter a new Quest</span><div class="questTimer pull-right text-muted">'+moment().fromNow()+'</div></li>'))
		$('.questName').hallo({editable : true})
		

	$(document).on 'click', '.addDaily', () ->
		$('.dailyQuestList').append($('<li class="daily list-unstyled"><div class="dailyStatus"></div><span class="dailyName">Enter a new Daily</span></li>'))
		$('.dailyName').hallo({editable : true})

	$(document).on 'halloactivated', '.questName', () ->
		quest = $(@).text()
		$.post '/removeQuest', {questName : quest}, () ->
	
	$(document).on 'hallodeactivated', '.questName', () ->
		$(@).fadeOut('fast').fadeIn('fast')
		quest = $(@).text()
		$.post '/updateQuest', {questName : quest}, () ->

	$(document).on 'halloactivated', '.dailyName', () ->
		daily = $(@).text()
		$.post '/removedaily', {dailyName : daily}, () ->

	$(document).on 'hallodeactivated', '.dailyName', () ->
		$(@).fadeOut('fast').fadeIn('fast')
		daily = $(@).text()
		$.post '/updateDaily', {dailyName : daily}, () ->
		
	checkOffQuest = (type, el) ->
		questDone = $(el).parent()
		questName = $(el).next().text()
		if type is 'quest'
			expGain = Math.floor(Math.random()*25 + 1)
		else
			expGain = Math.floor(Math.random()*60 + 1)
		console.log questName
		questDone.fadeOut() # need better animation - sword slash maybe?
		socket.emit 'finish' + type, { user : currentUser, questName : questName, expGain : expGain } #this will remove the task from the database and give the user XP

	$(document).on 'click', '.questStatus', () ->
		checkOffQuest('Quest', @)

	$(document).on 'click', '.dailyStatus', () ->
		checkOffQuest('Daily', @)

	socket.on 'connected', (data) ->
		console.log 'connected'
	socket.on 'updateChar', (character) ->
		console.log character
		updateDashboard(character)




	return




