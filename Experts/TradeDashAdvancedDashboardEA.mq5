//+------------------------------------------------------------------+
//|     TradeDash MT5 EA (Direct Price SL/TP + Trailing)             |
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"
#property description "On-chart MT5 trade dashboard with direct price SL/TP, trailing stop, and live account stats."

#include <Trade/Trade.mqh>
#include <Controls/Button.mqh>
#include <Controls/Edit.mqh>
#include <Controls/Label.mqh>

CTrade trade;

//--- UI Elements
CButton btnBuy, btnSell, btnTrail, btnExit;
CEdit inputSL, inputTP, inputLot;
CLabel lblSL, lblTP, lblLot;

//--- Stats Labels
CLabel lblProfit, lblDD, lblSpread, lblTrades;

//--- Settings
bool trailing_enabled = false;

//+------------------------------------------------------------------+
int OnInit()
{
   CreatePanel();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void CreatePanel()
{
   int chart_width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);

   int x_start = chart_width - 180;
   int y_start = 40;

   // --- LOT
   lblLot.Create(0, "lblLot", 0, x_start, y_start, x_start + 70, y_start + 20);
   lblLot.Text("Lot:");
   lblLot.Color(clrWhite);

   inputLot.Create(0, "LOT", 0, x_start + 70, y_start - 5, x_start + 150, y_start + 25);
   inputLot.Text("0.01");

   // --- TP
   lblTP.Create(0, "lblTP", 0, x_start, y_start + 40, x_start + 70, y_start + 60);
   lblTP.Text("TP:");
   lblTP.Color(clrWhite);

   inputTP.Create(0, "TP", 0, x_start + 70, y_start + 35, x_start + 150, y_start + 65);
   inputTP.Text("10");

   // --- SL
   lblSL.Create(0, "lblSL", 0, x_start, y_start + 80, x_start + 70, y_start + 100);
   lblSL.Text("SL:");
   lblSL.Color(clrWhite);

   inputSL.Create(0, "SL", 0, x_start + 70, y_start + 75, x_start + 150, y_start + 105);
   inputSL.Text("2");

   // --- BUY
   btnBuy.Create(0, "BUY", 0, x_start, y_start + 120, x_start + 150, y_start + 160);
   btnBuy.Text("BUY");
   btnBuy.ColorBackground(clrGreen);

   // --- SELL
   btnSell.Create(0, "SELL", 0, x_start, y_start + 170, x_start + 150, y_start + 210);
   btnSell.Text("SELL");
   btnSell.ColorBackground(clrRed);

   // --- TRAIL
   btnTrail.Create(0, "TRAIL", 0, x_start, y_start + 220, x_start + 150, y_start + 260);
   btnTrail.Text("TRAIL OFF");
   btnTrail.ColorBackground(clrOrange);

   // --- EXIT ALL
   btnExit.Create(0, "EXIT", 0, x_start, y_start + 270, x_start + 150, y_start + 310);
   btnExit.Text("EXIT ALL");
   btnExit.ColorBackground(clrBlue);

   // --- STATS
   int y_offset = y_start + 330;

   lblProfit.Create(0, "lblProfit", 0, x_start, y_offset, x_start + 150, y_offset + 20);
   lblProfit.Text("Profit: 0");

   lblDD.Create(0, "lblDD", 0, x_start, y_offset + 25, x_start + 150, y_offset + 45);
   lblDD.Text("DD: 0");

   lblSpread.Create(0, "lblSpread", 0, x_start, y_offset + 50, x_start + 150, y_offset + 70);
   lblSpread.Text("Spread: 0");

   lblTrades.Create(0, "lblTrades", 0, x_start, y_offset + 75, x_start + 150, y_offset + 95);
   lblTrades.Text("Trades: 0");
}

//+------------------------------------------------------------------+
void UpdatePanelPosition()
{
   int chart_width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);

   int x_start = chart_width - 180;
   int y_start = 40;

   lblLot.Move(x_start, y_start);
   inputLot.Move(x_start + 70, y_start - 5);

   lblTP.Move(x_start, y_start + 40);
   inputTP.Move(x_start + 70, y_start + 35);

   lblSL.Move(x_start, y_start + 80);
   inputSL.Move(x_start + 70, y_start + 75);

   btnBuy.Move(x_start, y_start + 120);
   btnSell.Move(x_start, y_start + 170);
   btnTrail.Move(x_start, y_start + 220);
   btnExit.Move(x_start, y_start + 270);

   int y_offset = y_start + 330;

   lblProfit.Move(x_start, y_offset);
   lblDD.Move(x_start, y_offset + 25);
   lblSpread.Move(x_start, y_offset + 50);
   lblTrades.Move(x_start, y_offset + 75);
}

//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id == CHARTEVENT_CHART_CHANGE)
      UpdatePanelPosition();

   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      double sl_val = StringToDouble(inputSL.Text());
      double tp_val = StringToDouble(inputTP.Text());
      double lot    = StringToDouble(inputLot.Text());

      if(sparam == "BUY")
         PlaceTrade(ORDER_TYPE_BUY, sl_val, tp_val, lot);

      if(sparam == "SELL")
         PlaceTrade(ORDER_TYPE_SELL, sl_val, tp_val, lot);

      if(sparam == "TRAIL")
      {
         trailing_enabled = !trailing_enabled;
         btnTrail.Text(trailing_enabled ? "TRAIL ON" : "TRAIL OFF");
      }

      if(sparam == "EXIT")
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(PositionSelectByTicket(ticket))
               trade.PositionClose(ticket);
         }
      }
   }
}

//+------------------------------------------------------------------+
void PlaceTrade(ENUM_ORDER_TYPE type, double sl_val, double tp_val, double lot)
{
   double price = iClose(NULL, PERIOD_CURRENT, 0);

   if(type == ORDER_TYPE_BUY)
      trade.Buy(lot, _Symbol, price, price - sl_val, price + tp_val);
   else
      trade.Sell(lot, _Symbol, price, price + sl_val, price - tp_val);
}

//+------------------------------------------------------------------+
void UpdateStats()
{
   double total_profit = 0;
   int total_positions = PositionsTotal();

   for(int i = 0; i < total_positions; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
         total_profit += PositionGetDouble(POSITION_PROFIT);
   }

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double drawdown = balance - equity;

   double spread = SymbolInfoDouble(_Symbol, SYMBOL_ASK) -
                   SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // --- Smart Colors
   lblProfit.Color(total_profit >= 0 ? clrGreen : clrRed);
   lblDD.Color(clrRed);
   lblSpread.Color(clrYellow);
   lblTrades.Color(clrAqua);

   lblProfit.Text("Profit: " + DoubleToString(total_profit, 2));
   lblDD.Text("DD: " + DoubleToString(drawdown, 2));
   lblSpread.Text("Spread: " + DoubleToString(spread, 5));
   lblTrades.Text("Trades: " + IntegerToString(total_positions));
}

//+------------------------------------------------------------------+
void OnTick()
{
   UpdateStats();

   if(!trailing_enabled) return;

   double trail_val = StringToDouble(inputSL.Text());

   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong ticket = PositionGetTicket(i);

      if(PositionSelectByTicket(ticket))
      {
         int type = (int)PositionGetInteger(POSITION_TYPE);
         double sl = PositionGetDouble(POSITION_SL);
         double tp = PositionGetDouble(POSITION_TP);

         if(type == POSITION_TYPE_BUY)
         {
            double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double new_sl = price - trail_val;

            if(new_sl > sl)
               trade.PositionModify(ticket, new_sl, tp);
         }

         if(type == POSITION_TYPE_SELL)
         {
            double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double new_sl = price + trail_val;

            if(new_sl < sl || sl == 0)
               trade.PositionModify(ticket, new_sl, tp);
         }
      }
   }
}
