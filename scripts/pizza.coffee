# TODO
#   - start an order (only certain people)
#   - order for someone else

module.exports = (robot) ->

    # robot.brain.get('pizzaOrders') or []
    # does this persist after restarts ?
    robot.brain.data.currentPizzaOrder =
      pizzas: {},
      date: null},
    robot.brain.data.pizzaOrderHistory = robot.brain.data.pizzaOrderHistory or []

    pizzas =
      current: ->
        obj = robot.brain.data.currentPizzaOrder.pizzas
        Object.keys(obj).map((key) ->
          obj[key]
        ).join()

      currentQty: ->
        Object.keys(robot.brain.data.currentPizzaOrder.pizzas).length

      currentEaters: ->
        Object.keys(robot.brain.data.currentPizzaOrder.pizzas).join()

      add: (user, name) ->
        # only 1 pizza per user atm
        robot.brain.data.currentPizzaOrder.pizzas[user] = name

      remove: (user) ->
        delete robot.brain.data.currentPizzaOrder.pizzas[user]
        true

      closeOrder: ->
        robot.brain.data.currentPizzaOrder.date = Date.now()
        order = robot.brain.data.currentPizzaOrder
        robot.brain.data.pizzaOrderHistory.push order
        pizzas.clearOrder()
        order

      clearOrder: ->
        robot.brain.data.currentPizzaOrder = {pizzas: {}, date: null}

      getHistory: ->
        order_qty = robot.brain.data.pizzaOrderHistory.length
        pizza_qty = 0
        for order in robot.brain.data.pizzaOrderHistory
          pizza_qty += Object.keys(order.pizzas).length
        "#{pizza_qty} pizzas ordered in #{order_qty} orders"

    robot.respond /^pizza (.*)/i, (msg) ->
      sender = msg.message.user.name.toLowerCase()
      pizza = msg.match[1]
      pizzas.add(sender, pizza)
      msg.reply "One pizza #{pizza} ordered, already #{pizzas.currentQty()} on the list"

    robot.respond /no pizza for me/i, (msg) ->
      sender = msg.message.user.name.toLowerCase()
      pizzas.remove(sender)
      msg.reply "Ok... I cancelled your order... pussy"

    robot.respond /order pizzas/i, (msg) ->
      qty = pizzas.currentQty()
      heroes = pizzas.currentEaters()
      names = pizzas.current()
      order = pizzas.closeOrder()
      msg.send "Pizza order CLOSED, you should now order:"
      msg.send "#{qty} pizzas: #{names}"
      msg.send "Pizza heroes of today are #{heroes}"




    # $('.add').on 'click', (e) ->
    #     exp.pizzas.addPizza($(this).data('user'), $(this).data('name'))
    #     $('#test').html(exp.pizzas.showCurrent())

    # $('.clear').on 'click', (e) ->
    #     exp.pizzas.clearOrder()
    #     $('#test').html(exp.pizzas.showCurrent())

    # $('.close').on 'click', (e) ->
    #     exp.pizzas.closeOrder()

    #     $('#test').html(exp.pizzas.showCurrent())
    #     $('.history').html('')
    #     for order in exp.pizzas.getHistory()
    #         $('.history').append($('<p>').html("date: "+ order.date + " - eaters: "+ Object.keys(order.pizzas).join() ))




