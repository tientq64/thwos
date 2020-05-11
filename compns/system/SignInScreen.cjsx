class SignInScreen extends React.Component
	constructor: (props) ->
		super props
		@$autoBind()

		@password = ""
		@errorTextPassword = ""
		@signInMethod = ap.user.signInMethod
		@inputEl = null
		@placeholdersPassword =
			password: "Mật khẩu"
			pin: "Mã PIN"

	onChangePassword: (event) ->
		@password = event.target.value
		@errorTextPassword = ""
		if @signInMethod is "pin"
			@submitSignIn()
		@setState {}
		return

	onSubmitSignInForm: (event) ->
		event.preventDefault()
		@submitSignIn()
		return

	submitSignIn: ->
		password = ap["validate#{_.upperFirst @signInMethod}"] @password
		if _.isError password
			if @signInMethod is "password"
				@errorTextPassword = password.message
				@inputEl.focus()
		else
			password = md5.md5 password, 32
			if ap.user[@signInMethod] is password
				ap.main()
			else
				if @signInMethod is "password"
					@errorTextPassword = "Mật khẩu không đúng"
					@inputEl.focus()
		@setState {}
		return

	componentDidMount: ->
		if ap.user.password is "670b14728ad9902aecba32e22fa4f6bd"
			@password = "000000"
			@submitSignIn()
			@setState {}
		return

	render: ->
		<div className="column full middle p-4 text-center bg-light-gray3">
			<div className="col row middle">
				<form
					style={width: 280}
					onSubmit={@onSubmitSignInForm}
				>
					<img
						className="img-cover rounded"
						src={ap.user.avatar}
						width={128}
						height={128}
					/>
					<H3 className="mt-3">{ap.user.name}</H3>
					<FormGroup
						intent={"danger" if @errorTextPassword}
						helperText={@errorTextPassword}
					>
						<InputGroup
							autoFocus
							type="password"
							intent={"danger" if @errorTextPassword}
							placeholder={@placeholdersPassword[@signInMethod]}
							inputRef={(@inputEl) =>}
							value={@password}
							onChange={@onChangePassword}
						/>
					</FormGroup>
					<Button
						className="mt-3"
						type="submit"
						intent="primary"
						text="Đăng nhập"
					/>
				</form>
			</div>
			<Popover
				minimal
				content={
					ap.menuToJsx [
						divider: "Đăng nhập sử dụng"
					,
						text: "Mã PIN"
						shown: ap.user.pin
						onClick: =>
							unless @signInMethod is "pin"
								@signInMethod = "pin"
								@password = ""
								@errorTextPassword = ""
								@setState {}
							return
					,
						text: "Mật khẩu"
						onClick: =>
							unless @signInMethod is "password"
								@signInMethod = "password"
								@password = ""
								@errorTextPassword = ""
								@setState {}
							return
					],
					style:
						minWidth: 240
				}
			>
				<Button text="Các tùy chọn đăng nhập khác"/>
			</Popover>
		</div>
