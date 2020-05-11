WIN = yes
TID = "{{tid}}"
app = null

task = new Proxy
	params: null
	env: null
	messageIfrSysIfrResolves: []
	contextMenuEvents: {}
	loadedLibs: []
	isAutoSize: no

	import: (paths) ->
		paths = _.castArray paths
			.filter (path) => path not in @loadedLibs
			.map (path) =>
				@loadedLibs.push path
				if exec = /^(npm|gh):(.+)$/.exec path
					path = "https://cdn.jsdelivr.net/#{exec[1]}/#{exec[2]}"
				path
			.map (path) =>
				new Promise (resolve) =>
					ext = task.pathExtname path
					code =
						if /^https?:\/\//.test path then await (await fetch path).text()
						else await task.readFile path
					switch ext
						when "coffee"
							await @import "gh:tiencoffee/libs/coffee.min.js"
							code = coffee.compile code, bare: yes
							resolve [code]
						when "cjsx"
							await @import ["gh:tiencoffee/libs/coffee.min.js", "npm:babel-standalone@6.26.0"]
							code = coffee.compile code, bare: yes
							{code} = Babel.transform code,
								presets: ["react"]
								plugins: ["syntax-object-rest-spread"]
							resolve [code]
						when "styl"
							await @import "gh:tiencoffee/libs/stylus.min.js"
							code = stylus.render code
							resolve [code, "css"]
						when "css"
							resolve [code, "css"]
						else
							resolve [code]
					return
		for [code, type] from await Promise.all paths
			switch type
				when "css"
					el = document.createElement "style"
					el.textContent = code
					document.head.appendChild el
				else
					window.eval code
		return

	showContextMenu: (menu, onClose) ->
		@contextMenuEvents = {}
		menuData = []
		do handle = (menu, menuData) =>
			for props from menu
				if props
					if props.onClick
						uuid = uuidv4()
						@contextMenuEvents[uuid] = props.onClick
						props.onClick = uuid
					menuData.push props
					if props.submenu
						submenu = props.submenu
						props.submenu = []
						handle submenu, props.submenu
			return
		uuid = await task["sendContextMenu#{TID}"] menuData
		@contextMenuEvents[uuid]()
		onClose?()
		return

	setSizeWinFitContent: (timeout) ->
		setTimeout =>
			document.body.classList.add "__fix-autosize"
			task["iframeDidResize#{TID}"] document.body.offsetWidth, document.body.offsetHeight
			document.body.classList.remove "__fix-autosize"
			return
		, timeout
		return
,
	get: (target, name) =>
		if name of target
			if typeof target[name] is "function"
				target[name].bind target
			else target[name]
		else (...val) =>
			new Promise (resolve) =>
				mid = uuidv4()
				target.messageIfrSysIfrResolves[mid] = resolve
				window.top.postMessage {name, val, mid, tid: TID}, "*"
				return

	set: (target, name, val) =>
		target[name] = val
		yes

ap = window.ap or task

window.addEventListener "message", (event) =>
	switch event.data.type
		when "ifrSysIfr"
			{val, mid} = event.data
			task.messageIfrSysIfrResolves[mid] val
			delete task.messageIfrSysIfrResolves[mid]
		when "sysIfr"
			(({name, val}) =>
				if app.$listen
					if name is "$entries"
						val = await task.spliceEntriesTask()
					app.$listen name, val
				return
			) event.data
	return

await do =>
	document.getElementById("script-app").remove()
	[task.params, task.env, task.isAutoSize] = await Promise.all [
		task.getParamsTask()
		task.getEnvTask()
		task.getIsAutoSize()
	]
	Object.assign task, ```{{@sharedMethods}}```
	onMouseDownUpApp = ({x, y, type}) =>
		if task.env.isSystem then ap.dispatchMouseDownUpApp x, y, type, TID
		else task["dispatchMouseDownUpApp#{TID}"] x, y, type, TID
		return
	document.addEventListener "mousedown", onMouseDownUpApp, yes
	document.addEventListener "mouseup", onMouseDownUpApp, yes
	return

App = null
await ((TID) =>
	{{code}}
	App = {{name}}
	((componentWillMount, componentDidUpdate, componentDidMount) =>
		App::[componentWillMount] = App::componentWillMount
		App::componentWillMount = ->
			app = @
			@[componentWillMount]?.call @
			return
		App::[componentDidUpdate] = App::componentDidUpdate
		App::componentDidUpdate = ->
			task.setSizeWinFitContent() if task.isAutoSize
			@[componentDidUpdate]?.call @
			return
		App::[componentDidMount] = App::componentDidMount
		App::componentDidMount = ->
			await @[componentDidMount]?.call @
			if @$listen
				evt = new MessageEvent "message", data:
					type: "sysIfr"
					name: "$entries"
				window.dispatchEvent evt
			return
	) Symbol("componentWillMount"), Symbol("componentDidUpdate"), Symbol("componentDidMount")
	if App.defaultParams
		task.params = _.merge {}, App.defaultParams, task.params
	return
)()

ReactDOM.render <App/>, document.getElementById("app"), =>
	await task["iframeDidMount#{TID}"]()
	task.setSizeWinFitContent 10
	return
