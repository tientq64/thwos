class App extends React.Component
	constructor: (props) ->
		super props

		sharedMethods = "
			readFileObj
			pathDirname pathFilename pathBasename pathExtname pathJoin pathNormalize pathInPath
			menuToJsx
		"
			.split " "
			.map (name) => @[name] + ""
			.join ","
		sharedMethods = "{#{sharedMethods}}"

		@$autoBind()

		taskbarHeight = 36
		desktopX = 0
		desktopY = 0
		desktopWidth = innerWidth - desktopX
		desktopHeight = innerHeight - desktopY - taskbarHeight

		@stt = "boot"
		@user =
			name: "Vô danh"
			password: "670b14728ad9902aecba32e22fa4f6bd"
			avatar: ""
			pin: null
			signInMethod: "password"
		@desktop =
			x: 0
			y: 0
			width: desktopWidth
			height: desktopHeight
			path: "/A/desktop"
			background:
				base64: ""
				fit: "cover"
				color: "#fff"
			task: null
		@taskbar =
			height: taskbarHeight
			placement: "bottom"
		@moment = moment()
		@appls = {}
		@tasks = {}
		@taskFocused = null
		@exts = {}
		@maxLevelShortcut = 16
		@mouse =
			x: 0
			y: 0
		@cursorTouchmove = ""
		@sharedMethods = sharedMethods
		@textEncoder = new TextEncoder
		@battery =
			level: undefined
			charging: no
			chargingTime: 0
			dischargingTime: 0

	validateFilename: (filename) ->
		filename = _.trim filename
		unless filename
			Error "Tên không được để trống"
		else if filename.length > 256
			Error "Tên dài tối đa 256 ký tự"
		else if filename in [".", ".."]
			Error "Tên không hợp lệ"
		else if /[\0\\\/:*?"<>|]/.test filename
			Error 'Tên không được chứa các ký tự \\ / : * ? " < > |'
		else filename

	validatePassword: (password) ->
		password += ""
		if password.length < 6
			Error "Mật khẩu dài tối thiểu 6 ký tự"
		else if password.length > 128
			Error "Mật khẩu dài tối đa 128 ký tự"
		else password

	validatePin: (pin) ->
		pin += ""
		if pin.length < 4
			Error "Mã PIN dài tối thiểu 4 ký tự"
		else if pin.length > 64
			Error "Mã PIN dài tối đa 64 ký tự"
		else pin

	setUserAvatar: (path) ->
		@user.avatar = await @readFile path, "DataURL"
		@setState {}
		return

	setDesktopBackgroundBase64: (path) ->
		@desktop.background.base64 = await @readFile path, "DataURL"
		@message @desktop.task, "$update"
		@setState {}
		return

	readFile: (path, type) ->
		path = await @resolveShortcut path
		fs.readFile path, {type}

	writeFile: (path, data = "", isAppend) ->
		path = await @resolveShortcut path
		unless _.isArrayBuffer data
			data = @textEncoder.encode(data).buffer
		entry = @statsEntry await fs[isAppend and "appendFile" or "writeFile"] path, data
		if @desktop.task and ap.pathDirname(path) is @desktop.path
			@message @desktop.task, "refresh"
		entry

	appendFile: (path, data) ->
		@writeFile path, data

	deleteFile: (path, moveToTrash) ->
		if moveToTrash then @movePathToTrash path
		else fs.unlink path

	saveFile: (opts) ->
		app.pickEntries
			kind: "save"
			filename: opts.name
			data: opts.data
			applPath: opts.applPath

	readFileObj: (file, type = "Text") ->
		new Promise (resolve) =>
			file = file.file if file.file
			reader = new FileReader
			reader.onload = (event) =>
				resolve event.target.result
				return
			reader["readAs#{type}"] file
			return

	createDir: (path) ->
		@statsEntry await fs.mkdir path

	readDir: (path, deep) ->
		entries = await fs.readdir path, {deep}
		handle = (entries) =>
			for entry from entries
				await @statsEntry entry
				if entry.children
					await handle entry.children
			return
		await handle entries
		entries

	deleteDir: (path, moveToTrash) ->
		if moveToTrash then @movePathToTrash path
		else fs.rmdir path

	movePathToTrash: (path) ->
		dirname = @pathDirname path
		filename = @pathFilename path
		filename = "#{filename} #{uuidv4()}|#{encodeURI dirname}"
		@statsEntry await fs.rename path, @pathJoin("/C/trash", filename)

	movePath: (path, newPath, create) ->
		@statsEntry await fs.rename path, newPath, {create}

	copyPath: (path, newPath, create) ->
		@statsEntry await fs.copy path, newPath, {create}

	existsPath: (path) ->
		fs.exists path

	usageFs: ->
		fs.usage()

	getEntry: (path) ->
		entry = await @resolveShortcut path, yes
		@statsEntry entry

	statsEntry: (entry) ->
		if entry.isFile
			entry.file = await fs.readFile entry, type: "File"
			entry.size = entry.file.size
			entry.lastModifiedDate = entry.file.lastModifiedDate
		else
			stats = await fs.stat entry
			entry.size = stats.size
			entry.lastModifiedDate = stats.modificationTime
		entry.icon = await @iconEntry entry
		entry

	cloneEntry: (entry) ->
		if entry.isClonedEntry
			entry
		else
			clone =
				name: entry.name
				isFile: entry.isFile
				isDirectory: entry.isDirectory
				fullPath: entry.fullPath
				size: entry.size
				lastModifiedDate: entry.lastModifiedDate
				icon: entry.icon
				isClonedEntry: yes
			if entry.isFile
				clone.file = entry.file
				clone.url = "filesystem:#{location.origin}/persistent#{entry.fullPath}"
			if entry.children
				clone.children = entry.children.map (v) => @cloneEntry v
			clone

	iconEntry: (entry) ->
		if entry.isFile
			ext = @pathExtname entry.name
			icon =
				if entry.name is "app.yml"
					dirname = @pathDirname entry.fullPath
					@appls[dirname]?.icon
				else if ext is "lnk"
					entry = await @resolveShortcut entry.fullPath, yes
					await @iconEntry entry
				else if /^(png|jpe?g|gif)$/.test ext
					"media"
				else if /^(mp3|wav|ogg)$/.test ext
					"music"
				else if /^(mp4)$/.test ext
					"video"
				else if /^(zip|tar)$/.test ext
					"archive"
				else if /^(html?|pug|s?css|styl(us)?|c?jsx|js|coffee|ts|xml|vue)$/.test ext
					"code"
			icon or "document"
		else "folder-close"

	createShortcut: (targetPath, shortcutPath) ->
		new Promise (resolve) =>
			basename = @pathBasename targetPath
			shortcutPath ?= "#{@desktop.path}/#{basename}.lnk"
			entry = @statsEntry await fs.writeFile shortcutPath, targetPath
			@message @desktop.task, "update"
			resolve entry
			return

	resolveShortcut: (path, returnEntry) ->
		count = 0
		while "lnk" is @pathExtname path
			if count++ >= @maxLevelShortcut
				throw Error "Shortcut quá nhiều cấp lồng nhau"
			entry = await fs.getEntry path
			if entry.isFile
				text = await fs.readFile path
				unless text[0] is "/"
					text = @pathJoin path, text
				path = text
			else break
		if returnEntry
			@statsEntry await fs.getEntry path
		else path

	openFilesWith: (files) ->
		files = _.castArray files
		@runTask "/C/programs/OpenFilesWith/app.yml", null, entries: files
		return

	pathDirname: (path) ->
		path.split("/")[...-1].join("/") or "/"

	pathFilename: (path) ->
		path = path.split "/"
		path[path.length - 1] or ""

	pathBasename: (path) ->
		name = @pathFilename(path).split(".")
		if name.length > 1 then name[...-1].join(".") else name[0]

	pathExtname: (path, keepDot) ->
		path = @pathFilename(path).split(".")[1..]
		ext = path[path.length - 1] or ""
		if keepDot then (ext and "." or "") + ext else ext

	pathJoin: (...paths) ->
		paths2 = []
		for path from paths
			path += ""
			paths2 = [] if path[0] is "/"
			paths2.push path
		@pathNormalize paths2.join "/"

	pathNormalize: (path, isSubPath) ->
		paths = (path + "").split /\/+/
		paths = paths.filter (v) => not /^(\.|\s+)?$/.test v
		while (index = paths.findIndex (v) => v is "..") >= 0
			if index then paths.splice index - 1, 2
			else paths.shift()
		path = paths.join "/"
		path = "/" + path unless isSubPath or path[0] is "/"
		path.replace /(?<=.)\/+$/, ""

	pathInPath: (path, parentPath) ->
		path = @pathNormalize(path) + "/"
		parentPath = @pathNormalize(parentPath) + "/"
		path.startsWith parentPath

	iconBattery: ->
		{level} = @battery
		if level > .05
			if level < .34
				"fas:battery-quarter"
			else if level < .67
				"fas:battery-half"
			else if level < .1
				"fas:battery-three-quarters"
			else "fas:battery-full"
		else "fas:battery-empty"

	createAppl: (data, inheritData) ->
		name: data.name
		path: inheritData.path
		icon: data.icon or "application"
		title: data.title
		exts: data.exts or []
		x: data.x
		y: data.y
		width: data.width
		height: data.height
		maxWidth: data.maxWidth
		maxHeight: data.maxHeight
		minimizable: data.minimizable ? yes
		maximizable: data.maximizable ? yes
		resizable: data.resizable ? yes
		fullscreenable: data.fullscreenable ? yes
		sameWin: data.sameWin
		picker: data.picker
		isSystem: inheritData.isSystem
		appls: inheritData.appls
		perms: inheritData.perms

	installApp: (files, {createShortcut} = {}) ->
		new Promise (resolve) =>
			if file = files.find (v) => v.endsWith "/app.yml"
				data = jsyaml.safeLoad await fetch2 file
				name = @validateFilename data.name
				unless _.isError name
					path = @pathDirname file
					isSystem = data.isSystem
					perms =
						paths: [path]
					appls = data.appls or []
					inheritData = {path, isSystem, perms, appls}
					appl = @createAppl data, inheritData
					for v, i in appls
						appls[i] = @createAppl v, inheritData
					for file from files
						res = await fetch file
						if res.status is 200
							text = await res.text()
							await @writeFile file, text
					@addApplExts appl, appl.exts
					if createShortcut
						@createShortcut "#{path}/app.yml", "#{@desktop.path}/#{appl.name}.lnk"
					@appls[path] = appl
					@setState {}
			resolve()
			return

	addApplExts: (appl, exts) ->
		for ext from exts
			@exts[ext] ?= appls: []
			{appls} = @exts[ext]
			appls.splice appls.indexOf(appl), 1 if appl in appls
			appls.unshift appl
		return

	runTask: (filePath, params, env, parentTask) ->
		console.log Date.now() % 1000
		file = await @resolveShortcut @pathNormalize(filePath), yes
		console.log Date.now() % 1000
		if file.isFile
			if not parentTask and file.name is "app.yml" or parentTask and file.name.endsWith ".cjsx"
				new Promise (resolve) =>
					console.log Date.now() % 1000
					tid = uuidv4()
					pid = +_.uniqueId()
					if parentTask
						name = ap.pathBasename file.name
						path = parentTask.appl.path
						code = await @readFileObj file.file
						console.log Date.now() % 1000
						appl = _.find @appls[path].appls, {name}
						unless appl
							appl = @createAppl
								name: name
							, parentTask.appl
						env = _.omit env, ["isSystem", "isDesktop"]
					else
						name = "App"
						path = @pathDirname file.fullPath
						code = await @readFile "#{path}/index.cjsx"
						console.log Date.now() % 1000
						appl = @appls[path]
					code = code.replace /\n/g, "\n\t"
					env = _.merge
						entries: []
						appl
						env
					env = _.omit env, ["path", "appls", "perms"]
					env.entries = await Promise.all env.entries.map (entry) =>
						if entry.isFile and entry.name.endsWith ".lnk"
							entry = await @resolveShortcut entry.fullPath, yes
						@cloneEntry entry
					console.log Date.now() % 1000
					params = Object.assign {}, params
					css = cssIframe
					try css += await @readFile "#{path}/index.styl"
					console.log Date.now() % 1000
					css = stylus.render css
					task =
						tid: tid
						pid: pid
						name: name
						appl: appl
						env: env
						entries: [...env.entries]
						code: code
						params: params
						win: null
						order: pid
						resolve: resolve
						tasks: []
						media:
							stream: null
							video: null
							g: null
							raf: 0
					if task.env.sameWin and not task.env.picker and not task.env.isDesktop
						task2 = _.find @tasks, (v) =>
							v.appl is appl and v.env.sameWin and not v.env.picker and not v.env.isDesktop
					if task2
						task2.entries.push ...env.entries
						@message task2, "$entries"
						@focusTask task2
					else
						code = codeIframe
							.replace /\{\{([=@]?)([\w.]+)\}\}/g, (s, s1, s2) =>
								switch s1
									when "=" then eval s2
									when "@" then eval "this.#{s2}"
									else _.get task, s2
							.replace /^|\n/g, (s) => s + "\t"
						code = coffee.compile "window.addEventListener 'load', ->\n#{code}\n\treturn", bare: yes
						{code} = Babel.transform code,
							presets: ["react"]
							plugins: ["syntax-object-rest-spread"]
						task.code = docIframe.replace /\{\{(code|css)\}\}/g, (s, s1) =>
							if s1 is "code" then code else css
						@tasks[tid] = task
						parentTask?.tasks.push task
					@setState {}
					console.log Date.now() % 1000
					return

	runPicker: (filePath, params, env, parentTask) ->
		env = Object.assign {}, env, picker: yes
		@runTask filePath, params, env, parentTask

	focusTask: (task) ->
		task = @tasks[task] if typeof task is "string"
		unless task.env.isDesktop or @taskFocused is task
			task.order = +_.uniqueId()
			@taskFocused = task
			@setState {}
		return

	blurTask: (tid) ->
		task = @tasks[tid]
		if @taskFocused is task or not tid
			task.order = 0 if tid
			tasks = _.filter @tasks, (v) =>
				not v.win?.isMinimized and not v.env.isDesktop
			taskMaxOrder = _.maxBy(tasks, "order")
			@taskFocused = taskMaxOrder
			@setState {}
		return

	killTask: (pid) ->
		if task = _.find @tasks, {pid}
			task.win.close()
			yes

	jsxToMenu: (jsx) ->
		return jsx if null
		if Array.isArray jsx
			jsx.map @jsxToMenu
		else if React.isValidElement jsx
			menuItem = {...jsx.props}
			switch jsx.type.displayName
				when "Blueprint3.MenuDivider"
					menuItem.divider = yes
					if menuItem.title
						menuItem.divider = menuItem.title
						delete menuItem.title
				else
					if submenu = menuItem.children
						delete menuItem.children
						menuItem.submenu = @jsxToMenu submenu
			menuItem
		else jsx

	menuToJsx: (menu, opts = {}, resolve, clickCb) ->
		if menu?.length
			hasItem = no
			key = 0
			menuEl = React.createElement Menu, opts, []
			do handle = (menu, menuEl) =>
				hasSubItem = no
				for props from menu
					props = props and {...props} or divider: yes
					props.key = key++
					if props.divider
						props.title = props.divider unless props.divider is yes
						delete props.divider
						for k, prop of props
							props[k] = prop() if typeof prop is "function"
						menuItemEl = React.createElement MenuDivider, props
						menuEl.props.children.push menuItemEl
					else
						props.shown = props.shown() if typeof props.shown is "function"
						if "shown" not of props or props.shown
							delete props.shown
							hasItem = yes
							hasSubItem = yes
							for k, prop of props
								props[k] = prop() if typeof prop is "function" and k isnt "onClick"
							if submenu = props.submenu
								props.tabIndex = ""
							delete props.submenu
							props.icon ?= ""
							props.icon += ""
							if opts.isDefaultBlankIcon
								props.icon or= "blank"
							if props.icon.includes ":"
								props.icon = <Icon icon={props.icon}/>
							if typeof props.onClick is "string"
								((uuid) =>
									props.onClick = =>
										resolve uuid
										return
								) props.onClick
							else if clickCb
								((onClick) =>
									props.onClick = =>
										clickCb()
										onClick?()
										return
								) props.onClick
							menuItemEl = React.createElement MenuItem, props, submenu and [] or null
							menuEl.props.children.push menuItemEl
							if submenu
								unless handle submenu, menuItemEl
									_.pull menuEl.props.children, menuItemEl
				hasSubItem
			hasItem and menuEl or null
		else null

	showContextMenu: (menu, onClose) ->
		new Promise (resolve) =>
			unless React.isValidElement menu
				menu = @menuToJsx menu, isDefaultBlankIcon: yes, resolve
			ContextMenu.show menu, onClose
			return

	alert: (message, isSafeHtml) ->
		@runTask "/C/programs/Popup/app.yml",
			kind: "alert"
			message: message
			isSafeHtml: isSafeHtml

	confirm: (message, isSafeHtml) ->
		@runTask "/C/programs/Popup/app.yml",
			kind: "confirm"
			message: message
			isSafeHtml: isSafeHtml

	prompt: (message, inputProps, isSafeHtml) ->
		@runTask "/C/programs/Popup/app.yml",
			kind: "prompt"
			message: message
			inputProps: inputProps
			isSafeHtml: isSafeHtml

	popup: (kind, params) ->
		@runTask "/C/programs/Popup/app.yml", {...params, kind}

	pickEntries: (params) ->
		@runTask "/C/programs/FileManager/app.yml", params, picker: yes

	addEntriesToApplPermPaths: (appl, entries) ->
		if entries
			for entry from _.castArray entries
				path = entry.fullPath
				unless appl.perms.paths.some (v) => @pathInPath path, v
					appl.perms.paths = appl.perms.paths
						.filter (v) => not @pathInPath v, path
						.concat path
					@setState {}
		return

	setCursorTouchmove: (cursor) ->
		@cursorTouchmove = cursor
		@setState {}
		return

	dispatchMouseDownUpApp: (x, y, type, tid) ->
		task = @tasks[tid]
		if task.win
			document.dispatchEvent new MouseEvent type
			task.win.onMouseDownWin() if type is "mousedown"
			rect = task.win.refs.iframe.getBoundingClientRect()
			@mouse.x = rect.x + x
			@mouse.y = rect.y + y
		return

	classApp: ->
		classNames
			"App__app--fullscreen": @taskFocused?.win?.isFullscreen is yes
			"App__app--fullscreenTaskbar": @taskFocused?.win?.isFullscreen is "taskbar"

	classMain: ->
		classNames
			"reverse": @taskbar.placement is "top"

	styleTaskbar: ->
		height: @taskbar.height

	styleTouchmove: ->
		cursor: @cursorTouchmove

	onContextMenuTaskBtns: (event) ->
		if event.target is event.currentTarget
			@showContextMenu [
				text: "Vị trí"
				submenu: [
					text: "Trên"
					onClick: =>
						@taskbar.placement = "top"
						@desktop.y = @taskbar.height
						@setState {}
						return
				,
					text: "Dưới"
					onClick: =>
						@taskbar.placement = "bottom"
						@desktop.y = 0
						@setState {}
						return
				]
			]
		return

	handleClickTaskBtn: (task) ->
		if @taskFocused is task
			task.win.minimize()
		else
			@focusTask task
			if task.win.isMinimized
				task.win.minimize no
		return

	onMouseMove: (event) ->
		@mouse.x = event.pageX - @desktop.x
		@mouse.y = event.pageY - @desktop.y
		return

	touchmoveCallback: (type) ->
		if type is 4
			@setCursorTouchmove ""
		return

	message: (task, name, val) ->
		task = @tasks[task] unless _.isPlainObject task
		task?.win?.refs.iframe?.contentWindow.postMessage
			type: "sysIfr"
			name: name
			val: val
			"*"
		return

	listen: (event) ->
		((mid, tid, task, handle) =>
			{name, val, mid, tid} = event.data
			task = @tasks[tid]
			if task?.win
				val = [] unless Array.isArray val
				handle = (name, val) =>
					switch name
						when "readFile"
							path = await task.win.requestPerm "paths", val[0]
							if _.isError path then path
							else @readFile path, val[1]

						when "writeFile", "appendFile"
							path = await task.win.requestPerm "paths", val[0]
							if _.isError path then path
							else @cloneEntry await @[name] path, val[1]

						when "deleteFile", "deleteDir"
							path = await task.win.requestPerm "paths", val[0]
							if _.isError path then path
							else @[name] path

						when "createDir"
							path = await task.win.requestPerm "paths", val[0]
							if _.isError path then path
							else @cloneEntry await @createDir path

						when "readDir"
							path = await task.win.requestPerm "paths", val[0]
							if _.isError path then path
							else
								entries = await @readDir path
								entries.map (entry) => @cloneEntry entry

						when "movePath", "copyPath"
							path = await task.win.requestPerm "paths", val[0]
							if _.isError path then path
							else
								newPath = await task.win.requestPerm "paths", val[1]
								if _.isError newPath then newPath
								else @cloneEntry @[name] path, newPath, val[2]

						when "existsPath"
							path = await task.win.requestPerm "paths", val[0]
							if _.isError path then path
							else @existsPath path

						when "minimize", "maximize", "close", "fullscreen", "setTitle"
						, "alert", "confirm", "prompt", "popup"
							task.win[name] ...val

						when "getTitle"
							task.win.title

						when "pickEntries", "pickReadOnlyEntries"
							task.win[name] val[0]

						when "saveFile"
							task.win.saveFile val[0]

						when "runTask", "runPicker"
							path = await task.win.requestPerm "paths", val[0]
							if _.isError path then path
							else
								t = await task.win.runTask path, val[1], val[2]
								if _.find @tasks, t then null else t

						when "getParamsTask"
							task.params

						when "getEnvTask"
							entries: task.env.entries
							picker: task.env.picker
							isSystem: task.env.isSystem
							isDesktop: task.env.isDesktop

						when "spliceEntriesTask"
							task.entries.splice 0

						when "getIsAutoSize"
							task.win.isAutoSize

						when "initMedia"
							new Promise (resolve) =>
								navigator.getUserMedia val[0], (stream) =>
									task.media.stream = stream
									{width, height} = stream.getVideoTracks()[0].getSettings()
									task.media.video = document.createElement "video"
									task.media.video.srcObject = stream
									canvas = document.createElement "canvas"
									canvas.width = width
									canvas.height = height
									task.media.g = canvas.getContext "2d"
									task.media.video.oncanplay = (event) =>
										do task.media.raf = =>
											task.media.g.clearRect 0, 0, task.media.g.canvas.width, task.media.g.canvas.height
											task.media.g.drawImage task.media.video, 0, 0
											@message task, "$media", task.media.g.canvas.toDataURL "image/jpeg"
											requestAnimationFrame task.media.raf
											return
										return
									task.media.video.play()
									resolve
										width: width
										height: height
									return
								, (err) =>
									resolve err
									return
								return

						when "sendContextMenu#{tid}"
							@showContextMenu val[0]

						when "dispatchMouseDownUpApp#{tid}"
							@dispatchMouseDownUpApp val[0], val[1], val[2], tid
							undefined

						when "iframeDidMount#{tid}"
							task.win.iframeDidMount()
							undefined

						when "iframeDidResize#{tid}"
							task.win.iframeDidResize val[0], val[1]
							undefined
				returnVal = await handle name, val
				@tasks[tid]?.win?.refs.iframe.contentWindow.postMessage
					type: "ifrSysIfr"
					val: returnVal
					mid: mid
					"*"
			return
		)()
		return

	componentWillMount: ->
		window.ap = app = @
		return

	setStt: (stt) ->
		@stt = stt
		@setState {}
		return

	boot: ->
		@setStt "boot"
		return

	signIn: ->
		@setStt "signIn"
		return

	main: ->
		@setStt "main"
		unless @desktop.task
			task = await @runTask "/C/programs/FileManager/app.yml",
				path: @desktop.path
				view: "icons"
			, isDesktop: yes
			task.win.fullscreen "taskbar"
			# @runTask "/C/programs/CodeEditor/app.yml", null,
			# 	entries: [
			# 		await @getEntry "/C/programs/FileManager/index.styl"
			# 		await @getEntry "/test.cjsx"
			# 	]
			# @runTask "/C/programs/FileIO/app.yml"
			# @runTask "/C/programs/TaskManager/app.yml"
		return

	componentDidMount: ->
		@boot()
		return

	render: ->
		<div className="full no-scroll #{@classApp()}">
			{switch @stt
				when "boot"
					<BootScreen/>
				when "signIn"
					<SignInScreen/>
				when "main"
					<div className="column full App__main #{@classMain()}">
						<div className="col relative z-2">
							<TransitionGroup>
								{_.map @tasks, (task) =>
									<CSSTransition
										key={task.pid}
										classNames="Win__win--transition"
										timeout={enter: 0, exit: 300}
									>
										<Win tid={task.tid}/>
									</CSSTransition>
								}
							</TransitionGroup>
						</div>
						<Navbar className="col-0 row z-2 App__taskbar" style={@styleTaskbar()}>
							<NavbarGroup className="col-0">
								<TaskbarHome/>
								<NavbarDivider/>
							</NavbarGroup>
							<NavbarGroup className="col App__taskBtns" onContextMenu={@onContextMenuTaskBtns}>
								{_.map @tasks, (task) =>
									if task.win?.isLoaded and not task.env.isDesktop
										<Popover
											key={task.pid}
											targetClassName="w-100"
											minimal
											isContextMenu
											content={
												<Menu className="App__taskBtnContextMenu">
													<MenuDivider title={task.win.title}/>
													<MenuItem intent="danger" text="Đóng" onClick={=> task.win.close()}/>
												</Menu>
											}
										>
											<Button
												className="w-100 text-ellipsis App__taskBtn App__taskBtn--#{task.tid}"
												active={task is @taskFocused}
												alignText="left"
												icon={task.win.icon}
												text={task.win.title or " "}
												onClick={=> @handleClickTaskBtn task}
											/>
										</Popover>
								}
							</NavbarGroup>
							<NavbarGroup className="col-0">
								<NavbarDivider/>
								<Tooltip
									content={
										<span>
											{if @battery.charging
												if @battery.level is 100
													"Đã sạc đầy"
												else
													"Đang sạc"
											else
												"Không sạc"
											} {" "}
											({_.round @battery.level * 100}%)
										</span>
									}
								>
									<Button
										minimal
										icon={<Icon icon={@iconBattery()}/>}
									/>
								</Tooltip>
								<Popover
									minimal
									content={
										<div className="p-3">
											<h1 className="text-center">{@moment.format "HH:mm:ss"}</h1>
											<DatePicker defaultValue={@moment.toDate()}/>
										</div>
									}
								>
									<Tooltip
										content={
											<div className="text-capitalize">
												{@moment.format "dddd, DD MMMM, Y"}
											</div>
										}
									>
										<Button
											minimal
											text={@moment.format "dd, L, HH:mm"}
										/>
									</Tooltip>
								</Popover>
							</NavbarGroup>
						</Navbar>
					</div>
			}
			<div className="full App__touchmove" style={@styleTouchmove()}/>
		</div>

	renderHotkeys: ->
		<Hotkeys>
			<Hotkey
				global
				combo="h"
				label="Menu chính"
				preventDefault
				onKeyDown={=> TaskbarHome__btn?.click()}
			/>
		</Hotkeys>

HotkeysTarget App
