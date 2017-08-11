# Description:
#   Order Pizza
#
# Dependencies:
#
# Configuration:
#   None
#
# Commands:
#   hubby chess me - Creates a new game between yourself and another person in the room
#   hubby chess status - Gets the current state of the board
#   hubby chess move <to> - Moves a piece to the coordinate position using standard chess notation
#   hubby pizza me your-pizza-choice - Add a pizza to the running order
#   no pizza for me - Cancel your pizza
#   hubby pizza show/current - Show current pizza order
#   hubby pizza history - Show total pizza's ordered
#   hubby pizza start - ADMIN: Start Pizza order
#   hubby pizza cancel - ADMIN: Cancel current Pizza order
#   hubby pizza order/close "ADMIN - Order and confirm current Pizza order
#
# Author:
#   StijnP (XAOP)
#
levenshtein = require 'fast-levenshtein'
yaml = require 'js-yaml'

module.exports = (robot) ->

    pazza_menu = ['funghi', 'mano', 'rochus', 'margherita', 'carbonara', 'prosciutto', 'fratello', 'capricciosa', 'calzione', '4stagioni', 'rimini', 'vesuvio', 'vulcano', 'hawaii', 'peppina', 'napoletana', 'romana', 'extravaganza', '8gusti', 'pazza', 'boscaiola', 'montana', 'primavera', 'parmigiana', 'pollo', 'pescatore', '4formaggi', '6formaggi', 'scampis', 'bruschetta', 'toscana', 'patapizza']
    match_pizza = (order) ->
      # Normalization
      replacements = [[/seizoene(n)?/, "stagioni"],
                      [/kaze(n)?/, "formaggi"],
                      [/fromage(s)?/, "formaggi"],
                      [/fromaggi(o)?/, "formaggi"],
                      [/quat(t)?r(o|e)/, "4"],
                      [/sei/, "6"],
                      [/octo/, "8"],
                      [/vier/, "4"],
                      [/zes/, "6"],
                      [/acht/, "8"],
                      [/4 s/, "4s"],
                      [/4 f/, "4f"],
                      [/6 f/, "6f"],
                      [/8 g/, "8g"],
                      [/random/, pazza_menu[Math.round(Math.random()*pazza_menu.length)-1]]]
      normalized = replacements.reduce(((s, r) -> 
          s.replace(r[0], r[1])), order.toLowerCase())
      return normalized.split(" ").map((norm_word) ->
          pazza_menu.map((menu_item) ->
              [levenshtein.get(norm_word, menu_item), menu_item]
          ).sort()[0]
      ).sort()[0][1]

    robot.brain.data.pizzaOrderHistory = robot.brain.data.pizzaOrderHistory or []
    robot.brain.data.pizzaOrderHistoryBackup = robot.brain.data.pizzaOrderHistoryBackup or []

    pizzas =
      currentOrder: ->
        robot.brain.data.currentPizzaOrder

      current: ->
        obj = this.currentOrder().pizzas
        counted = yaml.safeDump(Object.keys(obj).reduce(((p, c) ->
          if p[obj[c]]
            p[obj[c]] += 1
          else
            p[obj[c]] = 1
          return p
        ), {}))


      start: ->
        order = this.currentOrder()
        if this.isStarted()
          unless order.startDate && order.startDate >= new Date(new Date() - 24 * 60 * 60 * 1000)
            this.closeOrder()
        order.status = 'open'
        order.startDate = order.startDate || new Date()

      isStarted: ->
        this.currentOrder().status == 'open'

      currentQty: ->
        Object.keys(this.currentOrder().pizzas).length

      currentEaters: ->
        Object.keys(this.currentOrder().pizzas).join()

      add: (user, name) ->
        # only 1 pizza per user atm
        this.currentOrder().pizzas[user] = name

      remove: (user) ->
        delete this.currentOrder().pizzas[user]
        true

      closeOrder: ->
        if pizzas.currentQty() > 0
          order = this.currentOrder()
          order.date = new Date()
          order.status = 'closed'
          robot.brain.data.pizzaOrderHistory.push order
          pizzas.newOrder()
          order
        else

      newOrder: ->
        robot.brain.data.currentPizzaOrder = {pizzas: {}, date: null, status: null}

      clearHistory: ->
        robot.brain.data.pizzaOrderHistoryBackup = robot.brain.data.pizzaOrderHistory
        robot.brain.data.pizzaOrderHistory = []
      restoreHistory: ->
        robot.brain.data.pizzaOrderHistory = robot.brain.data.pizzaOrderHistoryBackup

      getHistory: ->
        order_qty = robot.brain.data.pizzaOrderHistory.length
        pizza_qty = 0
        for order in robot.brain.data.pizzaOrderHistory
          pizza_qty += Object.keys(order.pizzas).length
        "#{pizza_qty} pizzas ordered in #{order_qty} orders"

    pizzas.newOrder()

    ## HELP ##
    robot.respond /pizza help/i, (msg) ->
      msg.send "Order a pizza: '@hubby pizza me your-pizza-choice'"
      msg.send "Show current pizza order: '@hubby pizza current'"
      msg.send "Cancel your pizza: 'no pizza for me'"
      msg.send "ADMIN - Start Pizza order: '@hubby pizza start'"
      msg.send "ADMIN - Cancel current Pizza order: '@hubby pizza cancel'"
      msg.send "ADMIN - Order and confirm current Pizza order: '@hubby pizza order'"

    ## ORDER a pizza ##
    robot.respond /pizza me (.*)/i, (msg) ->
      if pizzas.isStarted()
        sender = msg.message.user.name.toLowerCase()
        if /special/i.test(msg.match[1])
          pizza = msg.match[1].slice(8)
        else
          pizza = match_pizza(msg.match[1])
        pizzas.add(sender, pizza)
        msg.reply "One pizza #{pizza} ordered, now #{pizzas.currentQty()} on the list"
      else
        msg.send "Sorry, no running order at this time..."

    ## ORDER a pizza for someone else ##
    robot.respond /pizza for (\S+) (.*)/i, (msg) ->
      if pizzas.isStarted()
        external = "#{msg.message.user.name.toLowerCase()} for #{msg.match[1]}"
        if /special/i.test(msg.match[2])
          pizza = msg.match[2].slice(8)
        else
          pizza = match_pizza(msg.match[2])
        pizzas.add(external, pizza)
        msg.reply "One pizza #{pizza} ordered by #{external}, now #{pizzas.currentQty()} on the list"
      else
        msg.send "Apologize to #{msg.match[1]} for me, no running order at this time..."

    ## CANCEL your pizza order
    robot.hear /no pizza for me/i, (msg) ->
      sender = msg.message.user.name.toLowerCase()
      pizzas.remove(sender)
      msg.reply "Ok... I cancelled your order... pussy"

    ## CANCEL someone's pizza order
    robot.respond /no pizza for (\S+)/i, (msg) ->
      external = "#{msg.message.user.name.toLowerCase()} for #{msg.match[1]}"
      pizzas.remove(external)
      msg.reply "Ok... tell #{msg.match[1]} their order is cancelled"

    ## SHOW CURRENT order round ##
    robot.respond /pizza (current|show)/i, (msg) ->
      qty = pizzas.currentQty()
      if qty > 0
        heroes = pizzas.currentEaters()
        names = pizzas.current()
        msg.send "#{qty} pizzas:\n#{names}Pizza heroes of today are #{heroes}"
        # msg.send "Status is '#{robot.brain.data.currentPizzaOrder.current}'"
      else
        msg.send "No orders yet"
        msg.emote "me so sad :sob:"

    ## SHOW HISTORY ##
    robot.respond /pizza (history|stats)/i, (msg) ->
      count = 0
      for order in robot.brain.data.pizzaOrderHistory
        count += Object.keys(order['pizzas']).length
      msg.send "#{count} pizza's eaten in #{robot.brain.data.pizzaOrderHistory.length} orders"

    ## ADMIN - START a pizza ordering round ##
    robot.respond /pizza start/i, (msg) ->
      pizzas.start()
      robot.messageRoom "random", "Hero #{msg.message.user.name.toLowerCase()} started a :pizza: order - type 'hubby: pizza me your-pizza-choice' - come on, I know you want it..."
      today = new Date()
      if today.toString().match(/fri/i)
        msg.send "And since it's Friday, pizza's are FREE for all !! :raised_hands:"

    ## ADMIN - CLOSE a pizza ordering round ##
    robot.respond /pizza (order|close)/i, (msg) ->
      qty = pizzas.currentQty()
      if qty > 0
        heroes = pizzas.currentEaters()
        names = pizzas.current()
        order = pizzas.closeOrder()
        msg.send "Pizza order CLOSED, you should now order:"
        msg.send "#{qty} pizzas:\n#{names}Pizza heroes of today are #{heroes}"
      else
        msg.send "Nothing to close, you need to order first, silly! :pizza:"

    ## ADMIN - CLEAR running ordering round ##
    robot.respond /pizza (cancel|clear)/i, (msg) ->
      pizzas.clearOrder()
      msg.send "Running order cancelled... WHYYYYY did you do that?? :scream:"

    ## SUPERADMIN - clear order history ##
    robot.respond /pizza clearHistory/i, (msg) ->
      msg.reply "History cleared, I hope you know what you're doing... it's now a thing of the past, that's why they call it history"

    ## SUPERADMIN - restore order history ##
    robot.respond /pizza restoreHistory/i, (msg) ->
      msg.reply "History restored... I hope, time will tell... or not, because it's history."

