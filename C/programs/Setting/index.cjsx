class App extends React.Component
	constructor: (props) ->
		super props
		@$autoBind()

	render: ->
		<div className="full">
			<Tabs
				className="full"
				tabListClassName="p-3 scroll"
				vertical
			>
				<Tab
					id="account"
					panelClassName="p-3 scroll w-100"
					style={width: 200}
					panel={
						<div>
							<img
								className="img-cover rounded block mw-100 mh-100 mb-4"
								src={ap.user.avatar}
								width={240}
								height={240}
							/>
							<H3>{ap.user.name}</H3>
							{ap.menuToJsx [
								text: "Đổi tên"
							]}
							<br/>
							<H4>Tùy chọn đăng nhập</H4>
							{ap.menuToJsx [
								text: "Đổi mật khẩu"
								onClick: =>
									tsk.win.runTask "ChangePassword.cjsx"
									return
							,
								text: "Đặt mã PIN"
							]}
						</div>
					}
				>
					Tài khoản
				</Tab>
			</Tabs>
		</div>
