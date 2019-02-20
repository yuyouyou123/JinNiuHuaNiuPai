
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

local csbFilePath = 'res/MainLayer.csb'

--头像集合
local playerIcoPathList = {
	"Image/jnhjp_head2.png",
	"Image/jnhjp_head1.png",
	"Image/jnhjp_head3.png",
	"Image/jnhjp_head4.png",
}

--默认图片大小
local defCardSize = {width = 270,height = 350}

local otherPlayerHandCardScale = 0.23 --其他玩家手牌缩放
local playerHandCardScale = 0.46 --玩家手牌缩放
local deskCardScale = 0.26

local Pkoer_Color_Enum = {
	Hei 	= 1,
	Hong	= 2,
	Mei 	= 3,
	Fang	= 4,
}

local Player1CardOffsetX = 100 --玩家1的手牌偏移量


local pokersList = {
	{
		color = Pkoer_Color_Enum.Hei,
		value = 1,
		path = "Image/poker/poker_0_11.png",
	},
	{
		color = Pkoer_Color_Enum.Hei,
		value = 2,
		path = "Image/poker/poker_0_12.png",
	},
	{
		color = Pkoer_Color_Enum.Hei,
		value = 3,
		path = "Image/poker/poker_0_0.png",
	},
	{
		color = Pkoer_Color_Enum.Hei,
		value = 4,
		path = "Image/poker/poker_0_1.png",
	},
	{
		color = Pkoer_Color_Enum.Hei,
		value = 5,
		path = "Image/poker/poker_0_1.png",
	},
}


local function initCardList()
	pokersList = {}
	for color = 1,4 do
		for value = 1,13 do
			local pokerInfo = {}
			pokerInfo.value = value
			pokerInfo.color = color
			local valuePath = 0
			if value == 1 then
				valuePath = 11
			elseif value == 2 then
				valuePath = 12
			else
				valuePath = value - 3
			end
			pokerInfo.path = string.format("Image/poker/poker_%s_%s.png",color - 1,valuePath)
			table.insert(pokersList,pokerInfo)
		end
	end
end
initCardList()


--数组打乱
local function shuffle(t)
    if type(t)~="table" then
        return
    end
    local tab={}
    local index=1
    while #t~=0 do
        local n=math.random(0,#t)
        if t[n]~=nil then
            tab[index]=t[n]
            table.remove(t,n)
            index=index+1
        end
    end
    return tab
end

function MainScene:onCreate()
    self._csbNode = cc.CSLoader:createNode(csbFilePath)
    self._csbNode:addTo(self)
	--hall
	self.hallPanel = self._csbNode:getChildByName('Layout'):getChildByName('Panel_Start')
	self.hallStartButton = self.hallPanel:getChildByName('Button_Start')
	self.hallStartButton:addClickEventListener(handler(self, self.hallStartButtonCall))

	--selected
	self.selectPanel = self._csbNode:getChildByName('Layout'):getChildByName('Panel_SelectedPlayer')

	self.playerSelects = {}
	for i = 1,4 do
		local chekBox = self.selectPanel:getChildByName('CheckBox_' .. i)
			:setTag(i)
		table.insert(self.playerSelects,chekBox)
		chekBox:addEventListenerCheckBox(handler(self, self.chekBoxListener))

	end
	self.selectPanel:getChildByName('Button_StartGame'):addClickEventListener(handler(self, self.selectStartGame))
	self.selectPanel:getChildByName('Button_BackHall'):addClickEventListener(handler(self, self.backHallButton))

	--game
	self.gamePanel = self._csbNode:getChildByName('Layout'):getChildByName('Panel_Game')
	self.gamePanel:getChildByName('Button_Pass'):addClickEventListener(handler(self, self.passButton))
	self.gamePanel:getChildByName('Button_Exit'):addClickEventListener(handler(self, self.backHallButton))


	self:initHall()
    self:cleanTest()

    audio.playMusic("audio/Bubble_bgm.mp3",true)
end

function MainScene:initHall()
	self.hallPanel:setVisible(true)
	self.selectPanel:setVisible(false)
	self.gamePanel:setVisible(false)
end

function MainScene:backHallButton()
	audio.playSound('audio/button.mp3')
	self:initHall()
end
function MainScene:hallStartButtonCall()
	audio.playSound('audio/button.mp3')
	self.hallPanel:setVisible(false)
	self.selectPanel:setVisible(true)
	self.gamePanel:setVisible(false)
	self:chekBoxListener(self.playerSelects[self.playerIcoIndex or 1])
end

function MainScene:chekBoxListener(linstener)
	audio.playSound('audio/button.mp3')
	linstener:setSelected(true)
	for _,box in ipairs(self.playerSelects) do
		if box ~= linstener then
			box:setSelected(false)
		end
	end

	self.playerIcoIndex = linstener:getTag()
end

function MainScene:selectStartGame()
	audio.playSound('audio/button.mp3')

	self.hallPanel:setVisible(false)
	self.selectPanel:setVisible(false)
	self.gamePanel:setVisible(true)

    self:initPlayers()
    self:initDesks()
    self:faPai()
    self:gameStart()
end

function MainScene:passButton()
	audio.playSound('audio/button.mp3')
	self:playerOutCard(2)
end

function MainScene:initDesks()
	self.desks = {}
	for index,color in pairs(Pkoer_Color_Enum) do
		local desk = {}
		desk.cards = {}
		desk.parentNode = self._csbNode:getChildByName('Layout'):getChildByName('Panel_Game'):getChildByName('Node_DeskCards_' .. color)
		-- desk.color = color
		self.desks[color] = desk
		desk.parentNode:setScale(deskCardScale)
	end

	self:updateDesks()
end

function MainScene:updateDesks()
	for color ,desk in ipairs(self.desks) do
		local cards = desk.cards
		desk.parentNode:removeAllChildren()
		for index ,card in ipairs(cards)  do
			local model = cc.Sprite:create(card.path)
				:addTo(desk.parentNode)
			if card.value < 6 then
				model:setPosition(cc.p((card.value - 6) * defCardSize.width,0))
			elseif card.value == 6 then
				model:setPosition(cc.p(0,0))
			else
				model:setPosition(cc.p((card.value - 6) * defCardSize.width,0))
			end
		end
	end
end

function MainScene:initPlayers()
	--获取4个玩家
    self.players = {}
    for i = 1,4 do
    	local player = {}
    	player.cardsNode = self._csbNode:getChildByName('Layout'):getChildByName('Panel_Game'):getChildByName('Node_Player_' .. i):getChildByName('Cards')
    	player.head = self._csbNode:getChildByName('Layout'):getChildByName('Panel_Game'):getChildByName('Node_Player_' .. i):getChildByName('Head')
    	local icoId = self.playerIcoIndex 
    	if i ~= 1 then
    		icoId = self.playerIcoIndex + i -1
    		if icoId > 4 then
    			icoId = icoId - 4
    		end
    	end
    	self.players[i] = player

    	player.cardsNode:removeAllChildren()
    	player.head:setTexture(playerIcoPathList[icoId])

    	if i == 1 then
    		player.cardsNode:setScale(playerHandCardScale) --自己手牌缩放
    	else
    		player.cardsNode:setScale(otherPlayerHandCardScale) --其他玩家手牌缩放
    	end
    end
end

function MainScene:gameStart()
	for i,player in ipairs(self.players) do
		for index = #player.cards, 1 ,-1 do
			local card = player.cards[index]
			if card.value == 6 then
				table.remove(player.cards,index)
				self:ckeckCardIsOut(card)
				if card.model then
					local x,y = card.model:getPosition()
					local createPos = self.gamePanel:convertToNodeSpace(self.players[1].cardsNode:convertToWorldSpace(cc.p(x,y)))

					local tempDeskPosX = 0
					if card.value == 6 then
					else
						tempDeskPosX = (card.value - 6) * defCardSize.width
					end
					-- tempDeskPosX = tempDeskPosX * deskCardScale
					local tempDeskNode = self.desks[card.color].parentNode
					local endPos = self.gamePanel:convertToNodeSpace(tempDeskNode:convertToWorldSpace(cc.p(tempDeskPosX,0)))


					local sprite = cc.Sprite:create(card.path)
						:addTo(self.gamePanel)
						:setScale(playerHandCardScale)
						:setPosition(createPos)

					local actions = {}
					-- actions[#actions + 1] = cc.DelayTime:create(0.5)
					actions[#actions + 1] = cc.MoveTo:create(0.2,endPos)
					actions[#actions + 1] = cc.ScaleTo:create(0.1, deskCardScale, deskCardScale, deskCardScale)
					actions[#actions + 1] = cc.DelayTime:create(0.1)
					actions[#actions + 1] = cc.CallFunc:create(function(node)
						self:updateDesks()
						-- self:playerOutCard(2)
						node:removeSelf()
					end)
					sprite:runAction(cc.Sequence:create(actions))
					card.model:removeSelf()
				else

					local createPos = self.gamePanel:convertToNodeSpace(player.cardsNode:convertToWorldSpace(cc.p(0,0)))
					local tempDeskPosX = 0
					if card.value == 6 then
					else
						tempDeskPosX = (card.value - 6) * defCardSize.width
					end
					-- tempDeskPosX = tempDeskPosX * deskCardScale
					local tempDeskNode = self.desks[card.color].parentNode
					local endPos = self.gamePanel:convertToNodeSpace(tempDeskNode:convertToWorldSpace(cc.p(tempDeskPosX,0)))


					local sprite = cc.Sprite:create(card.path)
						:addTo(self.gamePanel)
						:setScale(otherPlayerHandCardScale)
						:setPosition(createPos)

					local actions = {}
					-- actions[#actions + 1] = cc.DelayTime:create(0.1)
					actions[#actions + 1] = cc.MoveTo:create(0.2,endPos)
					actions[#actions + 1] = cc.ScaleTo:create(0.1, deskCardScale, deskCardScale, deskCardScale)
					actions[#actions + 1] = cc.DelayTime:create(0.1)
					actions[#actions + 1] = cc.CallFunc:create(function(node)
						self:updateDesks()
						node:removeSelf()
					end)
					sprite:runAction(cc.Sequence:create(actions))


					player.countText:setTag(player.countText:getTag() - 1)
					player.countText:setString(player.countText:getTag())
				end
			end
		end
	end
	local actions = {}
	actions[#actions + 1] = cc.DelayTime:create(0.5)
	actions[#actions + 1] = cc.CallFunc:create(function()
		self:playerOutCard(1)
	end)
	self:runAction(cc.Sequence:create(actions))
end

function MainScene:faPai()
	local cards = shuffle(clone(pokersList))
	local index = 1
	for clinet ,player in ipairs(self.players) do
		local cardsNode = player.cardsNode
		player.cards = {}
		for count = 1,13 do
			local card = cards[index]
			index = index + 1
			if clinet == 1 then
				local cardImage = ccui.ImageView:create(card.path)
					:addTo(cardsNode)
					:setPosition(cc.p(0,0))
					:setTouchEnabled(true)
					:onTouch(handler(self, self.cardOnClicked))
					-- :setTag(count)
				card.model = cardImage
			end
			table.insert(player.cards, card)
		end

		if clinet ~= 1 then
			local sprite = cc.Sprite:create('Image/poker/poker_new8.png')
				:addTo(cardsNode)
			player.countText = ccui.Text:create("13","",200)
				:addTo(sprite)
				:setPosition(cc.p(defCardSize.width / 2,defCardSize.height / 2))
				:setTextColor(cc.c3b(0, 0, 0))
				:setTag(13)
		end
	end

	self:cardsSort(self.players[1].cards)
	audio.playSound('audio/fapai.mp3')

	-- self.isMeOutCard = true
end

function MainScene:cardOnClicked(touch)
	if touch.name ~= "ended" or not self.isMeOutCard then
		return 
	end
	audio.playSound('audio/button.mp3')
	local target = touch.target
	local card
	local indexCount = -1
	for count,tempCard in ipairs(self.players[1].cards)  do
		if tempCard.model == target then
			card = tempCard
			indexCount = count
		else
			self:setCardIsSelected(tempCard)
		end
	end

	if card.isSelected then
		-- print('出牌了，；；；；；',card)
		local isOk = self:ckeckCardIsOut(card)
		if isOk then
			table.remove(self.players[1].cards,indexCount)
			local x,y = card.model:getPosition()
			local createPos = self.gamePanel:convertToNodeSpace(self.players[1].cardsNode:convertToWorldSpace(cc.p(x,y)))

			local tempDeskPosX = 0
			if card.value == 6 then
			else
				tempDeskPosX = (card.value - 6) * defCardSize.width
			end
			-- tempDeskPosX = tempDeskPosX * deskCardScale
			local tempDeskNode = self.desks[card.color].parentNode
			local endPos = self.gamePanel:convertToNodeSpace(tempDeskNode:convertToWorldSpace(cc.p(tempDeskPosX,0)))


			local sprite = cc.Sprite:create(card.path)
				:addTo(self.gamePanel)
				:setScale(playerHandCardScale)
				:setPosition(createPos)

			local actions = {}
			-- actions[#actions + 1] = cc.DelayTime:create(0.5)
			actions[#actions + 1] = cc.MoveTo:create(0.2,endPos)
			actions[#actions + 1] = cc.ScaleTo:create(0.1, deskCardScale, deskCardScale, deskCardScale)
			actions[#actions + 1] = cc.DelayTime:create(0.1)
			actions[#actions + 1] = cc.CallFunc:create(function(node)
				self:updateDesks()
				self:playerOutCard(2)
				node:removeSelf()
			end)
			audio.playSound('audio/chupai.mp3')
			sprite:runAction(cc.Sequence:create(actions))


			card.model:removeSelf()
		else
			self:setCardIsSelected(card)
		end
	else
		self:setCardIsSelected(card,true)
	end
end

function MainScene:setCardIsSelected(card,selected)
	card.isSelected = selected or false
	if card.isSelected then
		card.model:setPositionY(50)
	else
		card.model:setPositionY(0)
	end
end

function MainScene:cardsSort(cards)
	table.sort(cards,function(card1,card2)
		if card2.color ~= card1.color then
			return card2.color < card1.color
		else
			return card2.value >  card1.value
		end
	end)

	for count,card in ipairs(cards) do
		if card.model then
			local move = cc.MoveTo:create(0.2,cc.p((count - 1) * Player1CardOffsetX,0))
			card.model:runAction(move)
			card.model:setLocalZOrder(count)
		end
	end
end


function MainScene:cleanTest()
	local test_1 = self._csbNode:getChildByName('Sprite_1')
	if test_1 then
		test_1:removeSelf()
	end
end

function MainScene:checkGameOver(playerId)
	if #self.players[playerId].cards == 0 then
		print('游戏结束 ，胜利玩家：',playerId)

		local spirte
		if playerId == 1 then
			spirte = cc.Sprite:create('Image/jnhjp_win.png')
		else
			spirte = cc.Sprite:create('Image/jnhjp_lose.png')
		end
		spirte:addTo(self.gamePanel)
			:setPosition(cc.p(display.width / 2,display.height / 2))
			:setScale(0.4)

		local actions = {}

		actions[#actions + 1] = cc.DelayTime:create(0.2)
		actions[#actions + 1] = cc.ScaleTo:create(0.4, 1, 1, 1)
		actions[#actions + 1] = cc.DelayTime:create(0.2)
		actions[#actions + 1] = cc.ScaleTo:create(0.4, 1.4, 1.4, 1.4)
		actions[#actions + 1] = cc.DelayTime:create(0.2)
		actions[#actions + 1] = cc.CallFunc:create(function()
			spirte:removeSelf()
			self:initHall()
		end)

		spirte:runAction(cc.Sequence:create(actions))
		return true
	end
end

--玩家出牌
function MainScene:playerOutCard(playerId)
	if self:checkGameOver(playerId - 1 == 0 and 4 or playerId - 1) then
		return
	end

	if playerId > 4 then
		playerId = 1
	end

	if playerId == 1 then --自己出牌
		self.isMeOutCard = true
		return 
	else
		self.isMeOutCard = false
		for count,tempCard in ipairs(self.players[1].cards)  do
			self:setCardIsSelected(tempCard)
		end
	end

	local player = self.players[playerId]
	player.cards = shuffle(player.cards)
	for index ,card in ipairs(player.cards) do
		local isOkOut = self:ckeckCardIsOut(card)
		if isOkOut then
			print('玩家：',playerId,'出牌了')
			table.remove(player.cards,index)

			local createPos = self.gamePanel:convertToNodeSpace(player.cardsNode:convertToWorldSpace(cc.p(0,0)))

			local tempDeskPosX = 0
			if card.value == 6 then
			else
				tempDeskPosX = (card.value - 6) * defCardSize.width
			end
			-- tempDeskPosX = tempDeskPosX * deskCardScale
			local tempDeskNode = self.desks[card.color].parentNode
			local endPos = self.gamePanel:convertToNodeSpace(tempDeskNode:convertToWorldSpace(cc.p(tempDeskPosX,0)))


			local sprite = cc.Sprite:create(card.path)
				:addTo(self.gamePanel)
				:setScale(otherPlayerHandCardScale)
				:setPosition(createPos)

			local actions = {}
			actions[#actions + 1] = cc.DelayTime:create(0.1)
			actions[#actions + 1] = cc.MoveTo:create(0.2,endPos)
			actions[#actions + 1] = cc.ScaleTo:create(0.1, deskCardScale, deskCardScale, deskCardScale)
			actions[#actions + 1] = cc.DelayTime:create(0.1)
			actions[#actions + 1] = cc.CallFunc:create(function(node)
				self:updateDesks()
				self:playerOutCard(playerId + 1)
				node:removeSelf()
			end)
			audio.playSound('audio/chupai.mp3')
			sprite:runAction(cc.Sequence:create(actions))


			player.countText:setTag(player.countText:getTag() - 1)
			player.countText:setString(player.countText:getTag())
			return
		end
	end
	self:playerOutCard(playerId + 1)
	print(playerId,'号玩家pass')
end

--检查这张牌能否出出去
function MainScene:ckeckCardIsOut(card)
	-- dump(self.desks, 'desk', nesting)
	local desk = self.desks[card.color]
	if card.value < 6 then
		for index ,deskCard in ipairs(desk.cards) do
			if deskCard.value == card.value + 1 then
				table.insert(desk.cards,card)
				return true
			end
		end
		return false
	elseif card.value == 6 then
		table.insert(desk.cards,card)
		-- if card.model then
		-- 	card.model:removeSelf()
		-- end
		return true
	else
		for index ,deskCard in ipairs(desk.cards) do
			if deskCard.value == card.value - 1 then
				table.insert(desk.cards,card)
				return true
			end
		end
		return false
	end
end

return MainScene
