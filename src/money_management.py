# Necessary imports
import pandas as pd


def generate_investment_table(
    num_trades: int, profit_percentage: float, desired_profit: float
) -> pd.DataFrame:
    """
    Generates a Money investment stratergy table which is based on Martingale
    stratergy.

    Args:
        num_trades (int): Number of trades to simulate.
        profit_percentage (float): Percentage profit to be made on each trade.
        desired_profit (float): The total desired profit to achieve.

    Returns:
        pd.DataFrame: A DataFrame containing trade details.
        float: The daily required amount for trading.
        float: The weekly required amount for trading.
    """
    trades = []
    cumulative_loss = 0

    # Calculate the initial amount to wager
    first_amount = desired_profit / (profit_percentage / 100)

    for i in range(num_trades):
        trade = {}

        # Determine the amount to wager to recover losses and make the desired profit
        if cumulative_loss == 0:
            amount_to_wager = first_amount
        else:
            amount_to_wager = (cumulative_loss + desired_profit) / (
                profit_percentage / 100
            )

        profit_if_successful = amount_to_wager * (profit_percentage / 100)
        total_return_if_successful = amount_to_wager + profit_if_successful

        trade["Trade"] = i + 1
        trade["Wager (€)"] = round(amount_to_wager, 2)
        trade["Profit if Successful (€)"] = round(profit_if_successful, 2)
        trade["Cumulative Loss (€)"] = round(cumulative_loss, 2)
        trade["Total Return if Successful (€)"] = round(total_return_if_successful, 2)
        trade["Net Profit if Successful (€)"] = round(
            profit_if_successful - cumulative_loss, 2
        )

        trades.append(trade)

        # Update cumulative_loss for the next iteration
        cumulative_loss += amount_to_wager

    trade_table = pd.DataFrame(trades)

    # Calculate required amounts for daily and weekly trading
    daily_req_amount = trade_table["Wager (€)"].sum()
    weekly_req_amount = daily_req_amount * 7

    return trade_table, daily_req_amount, weekly_req_amount
