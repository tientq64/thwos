class BootScreen extends React.Component
	constructor: (props) ->
		super props
		@$autoBind()

		@text = ""

	setText: (@text) ->
		@setState {}
		return

	componentDidMount: ->
		try
			@setText "Khởi tạo thời gian..."
			setInterval =>
				ap.moment = moment()
				ap.setState {}
				return
			, 1000
			@setText "Khởi tạo pin..."
			((battery) =>
				{
					level: ap.battery.level
					charging: ap.battery.charging
					chargingTime: ap.battery.chargingTime
					dischargingTime: ap.battery.dischargingTime
				} = battery
				battery.addEventListener "levelchange", =>
					ap.battery.level = battery.level
					ap.setState {}
					return
				battery.addEventListener "chargingchange", =>
					ap.battery.charging = battery.charging
					ap.setState {}
					return
				battery.addEventListener "chargingtimechange", =>
					ap.battery.chargingTime = battery.chargingTime
					ap.setState {}
					return
				battery.addEventListener "dischargingtimechange", =>
					ap.battery.dischargingTime = battery.dischargingTime
					ap.setState {}
					return
				return
			) await navigator.getBattery()
			@setText "Khởi tạo hệ thống tập tin..."
			await fs.init
				type: window.PERSISTENT
				bytes: 1024 * 1024 * 100
			@setText "Tải các tập tin..."
			await Promise.all Paths.fs.map (path) =>
				filePath = "/#{path}"
				if path.endsWith "/app.yml"
					ap.installApp [filePath], createShortcut: yes
				else if path.endsWith "/"
					ap.createDir filePath[...-1]
				else ap.writeFile filePath, await fetch2 path, "arrayBuffer"
			# @setText "Tải các tập tin lớn..."
			# paths = [
			# 	"roms/FIFA 2007.gba"
			# 	"roms/Grand Theft Auto Advance.gba"
			# 	"roms/Megaman Zero 4.gba"
			# 	"roms/Pokemon - Fire Red Version.gba"
			# 	"roms/Super Street Fighter II Turbo - Revival.gba"
			# ]
			# await Promise.all paths.map (path) =>
			# 	filePath = "/A/files/#{path}"
			# 	url = "https://cdn.jsdelivr.net/gh/tiencoffee/data/#{path}"
			# 	ap.writeFile filePath, await fetch2 url, "arrayBuffer"
			@setText "Đặt ảnh đại diện tài khoản..."
			await ap.setUserAvatar "/A/files/imgs/avatar.jpg"
			@setText "Đặt ảnh nền desktop..."
			await ap.setDesktopBackgroundBase64 "/A/files/imgs/galaxy.jpg"
			@setText "Khởi tạo các sự kiện..."
			window.addEventListener "message", ap.listen
			document.addEventListener "mousemove", ap.onMouseMove, yes
			Hammer.touchmoveCallback = ap.touchmoveCallback
			@setText "Đăng nhập..."
			ap.signIn()
		catch err
			@setText <span className="text-red3">Đã xảy ra lỗi: {err.message}</span>
		return

	render: ->
		<div className="column full center middle text-center bg-light-gray3">
			<div className="col-0">
				<H1 style={fontSize: 48}>ThwOS 1.0</H1>
				<Spinner className="mt-5"/>
				<div className="mt-5">{@text}</div>
			</div>
		</div>
