using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NinjaTrader.Cbi;
using NinjaTrader.Data;
using NinjaTrader.NinjaScript;
using NinjaTrader.NinjaScript.Indicators;
using NinjaTrader.NinjaScript.Strategies;

namespace NinjaTrader.NinjaScript.Strategies
{
    public class HalftrendStrategy : Strategy
    {
        private Halftrend halftrend;

        // User-defined inputs for Take Profit and Stop Loss
        [NinjaScriptProperty]
        [Range(1, int.MaxValue)]
        [Display(Name = "Take Profit (Points)", Description = "Take profit in points", Order = 1, GroupName = "Risk Management")]
        public int TakeProfitPoints { get; set; }

        [NinjaScriptProperty]
        [Range(1, int.MaxValue)]
        [Display(Name = "Stop Loss (Points)", Description = "Stop loss in points", Order = 2, GroupName = "Risk Management")]
        public int StopLossPoints { get; set; }

        // User-defined inputs for session start and end times
        [NinjaScriptProperty]
        [Display(Name = "Session Start Time", Description = "Start time for the trading session (HH:MM)", Order = 3, GroupName = "Session Settings")]
        public string SessionStartTime { get; set; }

        [NinjaScriptProperty]
        [Display(Name = "Session End Time", Description = "End time for the trading session (HH:MM)", Order = 4, GroupName = "Session Settings")]
        public string SessionEndTime { get; set; }

        private TimeSpan sessionStart;
        private TimeSpan sessionEnd;

        protected override void OnStateChange()
        {
            if (State == State.SetDefaults)
            {
                Description = "Halftrend Strategy for NQ Futures";
                Name = "HalftrendStrategy";
                Calculate = Calculate.OnBarClose;
                EntriesPerDirection = 1;
                EntryHandling = EntryHandling.AllEntries;
                IsExitOnSessionCloseStrategy = true;
                ExitOnSessionCloseSeconds = 30;
                IsFillLimitOnTouch = false;
                MaximumBarsLookBack = MaximumBarsLookBack.TwoHundredFiftySix;
                OrderFillResolution = OrderFillResolution.Standard;
                Slippage = 0;
                StartBehavior = StartBehavior.WaitUntilFlat;
                TimeInForce = TimeInForce.Gtc;
                TraceOrders = false;
                RealtimeErrorHandling = RealtimeErrorHandling.StopCancelClose;
                StopTargetHandling = StopTargetHandling.PerEntryExecution;
                BarsRequiredToTrade = 20;

                // Default values for Take Profit and Stop Loss
                TakeProfitPoints = 25;
                StopLossPoints = 50;

                // Default session times (9:30 AM to 4:00 PM)
                SessionStartTime = "09:30";
                SessionEndTime = "16:00";
            }
            else if (State == State.Configure)
            {
                // Parse session start and end times
                sessionStart = TimeSpan.Parse(SessionStartTime);
                sessionEnd = TimeSpan.Parse(SessionEndTime);

                // Add the Halftrend indicator
                halftrend = Halftrend(3, 3, 0.5);
                AddChartIndicator(halftrend);
            }
        }

        protected override void OnBarUpdate()
        {
            // Ensure we have enough bars to trade
            if (CurrentBar < BarsRequiredToTrade)
                return;

            // Check if we are within the user-defined session
            if (Times[0][0].TimeOfDay >= sessionStart && Times[0][0].TimeOfDay <= sessionEnd)
            {
                // Long entry condition
                if (halftrend.BuySignal[0] && Position.MarketPosition != MarketPosition.Long)
                {
                    // Close any open short position before entering long
                    if (Position.MarketPosition == MarketPosition.Short)
                        ExitShort("Close Short", "Short Entry");

                    EnterLong(1, "Long Entry");
                    SetProfitTarget("Long Entry", CalculationMode.Price, Position.AveragePrice + TakeProfitPoints * TickSize);
                    SetStopLoss("Long Entry", CalculationMode.Price, Position.AveragePrice - StopLossPoints * TickSize, false);
                }

                // Short entry condition
                if (halftrend.SellSignal[0] && Position.MarketPosition != MarketPosition.Short)
                {
                    // Close any open long position before entering short
                    if (Position.MarketPosition == MarketPosition.Long)
                        ExitLong("Close Long", "Long Entry");

                    EnterShort(1, "Short Entry");
                    SetProfitTarget("Short Entry", CalculationMode.Price, Position.AveragePrice - TakeProfitPoints * TickSize);
                    SetStopLoss("Short Entry", CalculationMode.Price, Position.AveragePrice + StopLossPoints * TickSize, false);
                }
            }
        }
    }
}