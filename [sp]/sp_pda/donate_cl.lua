local sw, sh = guiGetScreenSize ( )

xrDonate = {
	isEnabled = false
}

function xrDonate.init( canvas )
	local xml = xmlLoadFile( "PDAdonate.xml", true )
	if xml then
		canvas:insert( xml, canvas.frame )

		xmlUnloadFile( xml )
	end

	local donateRoot = canvas:getFrame( "CanvasDonate", true )
	xrDonate.donateRoot = donateRoot
	xrDonate.canvas = canvas

	donateRoot:getFrame( "MapBtn", true ):addHandler( xrDonate.onTabBtnPressed, xrMap )
	--donateRoot:getFrame( "OptionsBtn", true ):addHandler( xrDonate.onTabBtnPressed )

	for i = 1, 6 do
		local desc = DonateProducts[ i ]

		local frame = donateRoot:getFrame( "ProductEntry" .. i, true )
		if frame then
			frame:getFrame( "ValueLbl" ):setText( desc.name )
			frame:getFrame( "RubleLbl" ):setText( desc.nameSmall )

			frame:getFrame( "BuyBtn" ):addHandler( xrDonate.onSetBtnPressed, i )
		end
	end

	donateRoot:getFrame( "ProductEntry9", true ):getFrame( "BuyBtn2" ):addHandler( xrDonate.onSetBtnPressed, 9 )
	donateRoot:getFrame( "ProductEntry10", true ):getFrame( "BuyBtn3" ):addHandler( xrDonate.onSetBtnPressed, 10 )
	
	donateRoot:getFrame( "AddCoinsBtn", true ):addHandler( xrDonate.onAddCoinsBtn )	

	xrDonate.paymentWnd = donateRoot:getFrame( "PaymentWnd", true ):setVisible( false )
	xrDonate.paymentWnd:getFrame( "PaymentBtnOK", true ):addHandler( xrDonate.onPaymentBtnOK )
	xrDonate.paymentWnd:getFrame( "PaymentBtnCancel", true ):addHandler( xrDonate.onPaymentBtnCancel )

	xrDonate.browserWnd = donateRoot:getFrame( "BrowserWnd", true ):setVisible( false )
	xrDonate.browserWnd:getFrame( "CancelBtn" ):addHandler( xrDonate.onBrowserCancelBtn )

	xrDonate.errorWnd = donateRoot:getFrame( "ErrorWnd", true ):setVisible( false )
	xrDonate.errorWnd:getFrame( "AcceptBtn" ):addHandler( xrDonate.onErrorAcceptBtn )

	xrDonate.timeLbl = donateRoot:getFrame( "TimeLbl", true )
	xrDonate.rublesLbl = donateRoot:getFrame( "RublesLbl", true )

	donateRoot:setVisible( false )
end

function xrDonate:open()	
	if xrDonate.isEnabled then
		return
	end

	local money = getElementData( localPlayer, "money", false )
	xrDonate.rublesLbl:setText( tostring( money ) .. " ИГРОВЫХ РУБЛЕЙ" )
	
	xrDonate.donateRoot:setVisible( true )
	xrDonate.paymentWnd:setVisible( false )
	xrDonate.browserWnd:setVisible( false )
	xrDonate.errorWnd:setVisible( false )

	xrDonate.isEnabled = true
end

function xrDonate:close()
	if xrDonate.isEnabled then
		xrDonate.isEnabled = false

		xrDonate.donateRoot:setVisible( false )
	end
end

function xrDonate.onSetBtnPressed( index )
	xrDonate.paymentWnd:setVisible( true )

	local desc = DonateProducts[ index ]
	if desc then
		xrDonate.paymentWnd:getFrame( "ValueLbl33" ):setText( desc.name )
		xrDonate.paymentWnd:getFrame( "RubleLbl44" ):setText( desc.nameSmall )
		xrDonate.paymentWnd:getFrame( "PaymentImg" ):setTextureSection( desc.section )
		xrDonate.paymentWnd:getFrame( "RubleLbl54" ):setText( desc.price )
		xrDonate.paymentWnd:getFrame( "PaymentDescLnl" ):setText( desc.desc ):update()
	end
end

function xrDonate.onPaymentBtnOK()
	xrDonate.paymentWnd:setVisible( false )

	xrDonate.errorWnd:setVisible( true )
	xrDonate.errorWnd:getFrame( "ErrorLbl" ):setText( "Для покупки выбранного пакета у вас недостаточно монет" ):update()
end

function xrDonate.onPaymentBtnCancel()
	xrDonate.paymentWnd:setVisible( false )
end

function xrDonate.onAddCoinsBtn()
	xrDonate.browserWnd:setVisible( true )
	
end

function xrDonate.onBrowserCancelBtn()
	xrDonate.browserWnd:setVisible( false )
end

function xrDonate.onErrorAcceptBtn()
	xrDonate.errorWnd:setVisible( false )
end

function xrDonate.onTabBtnPressed( class )
	xrMain.onTabClicked( class )
end

function xrDonate.onRender()
	--[[
		Time
	]]
	local hours, mins = getTime()
	if hours < 10 then
		hours = "0" .. hours
	end
	if mins < 10 then
		mins = "0" .. mins
	end
	xrDonate.timeLbl:setText( hours .. " : " .. mins )
end

function xrDonate.onCursorMove( _, _, ax, ay )

end


function xrDonate.onCursorClick( btn, state, ax, ay )	
	
end

function xrDonate.onKey( btn, pressed )	

end