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

module.exports = (robot) ->

    robot.brain.data.pizzaOrderHistory = robot.brain.data.pizzaOrderHistory or []
    robot.brain.data.pizzaOrderHistoryBackup = robot.brain.data.pizzaOrderHistoryBackup or []

    pizzas =
      currentOrder: ->
        robot.brain.data.currentPizzaOrder

      current: ->
        obj = this.currentOrder().pizzas
        Object.keys(obj).map((key) ->
          obj[key]
        ).join()

      start: ->
        if this.isStarted()
          this.closeOrder()
        this.currentOrder().status = 'open'

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
        pizza = msg.match[1]
        pizzas.add(sender, pizza)
        msg.reply "One pizza #{pizza} ordered, now #{pizzas.currentQty()} on the list"
      else
        msg.send "Sorry, no running order at this time..."

    ## CANCEL your pizza order
    robot.hear /no pizza for me/i, (msg) ->
      sender = msg.message.user.name.toLowerCase()
      pizzas.remove(sender)
      msg.reply "Ok... I cancelled your order... pussy"

    ## SHOW CURRENT order round ##
    robot.respond /pizza (current|show)/i, (msg) ->
      qty = pizzas.currentQty()
      if qty > 0
        heroes = pizzas.currentEaters()
        names = pizzas.current()
        msg.send "#{qty} pizzas: #{names}"
        msg.send "Pizza heroes of today are #{heroes}"
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
        msg.send "#{qty} pizzas: #{names}"
        msg.send "Pizza heroes of today are #{heroes}"
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

