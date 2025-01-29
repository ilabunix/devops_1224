using NinjaTrader.Gui.Tools;
using NinjaTrader.NinjaScript;
using NinjaTrader.Data;
using NinjaTrader.NinjaScript.Strategies;
using NinjaTrader.NinjaScript.Indicators;
using NinjaTrader.NinjaScript.DrawingTools;
using System;
using System.Windows.Media;

namespace NinjaTrader.NinjaScript.Indicators
{
    public class Halftrend : Indicator
    {
        private ATR atrIndicator;
        private double atr;
        private double up;
        private double down;
        private int trend;
        private double buySignal;
        private double sellSignal;

        [Browsable(false)] // Hide from UI
        public double BuySignal { get; private set; }

        [Browsable(false)]
        public double SellSignal { get; private set; }

        protected override void OnStateChange()
        {
            if (State == State.SetDefaults)
            {
                Description = "Halftrend Indicator for NinjaTrader 8";
                Name = "Halftrend";
                Calculate = Calculate.OnBarClose;
                IsOverlay = true;
                DisplayInDataBox = true;
                DrawOnPricePanel = true;
                PaintPriceMarkers = true;
                IsSuspendedWhileInactive = true;

                AddPlot(Brushes.Green, "Trend");
                AddPlot(Brushes.Blue, "BuySignal");
                AddPlot(Brushes.Red, "SellSignal");
            }
            else if (State == State.DataLoaded)
            {
                atrIndicator = ATR(14);
            }
        }

        protected override void OnBarUpdate()
        {
            if (CurrentBar < 14) // Ensure ATR has enough data
                return;

            atr = atrIndicator[0];

            up = High[1] - atr;  // Using [1] to avoid repainting
            down = Low[1] + atr;

            if (Close[0] > down && trend != 1)
            {
                trend = 1;
                buySignal = Low[0];
                sellSignal = 0; // Reset sell signal
            }
            else if (Close[0] < up && trend != -1)
            {
                trend = -1;
                sellSignal = High[0];
                buySignal = 0; // Reset buy signal
            }
            else
            {
                buySignal = 0;
                sellSignal = 0;
            }

            Values[0][0] = trend == 1 ? 1 : -1;  // Trend Direction
            Values[1][0] = buySignal;
            Values[2][0] = sellSignal;

            BuySignal = buySignal;
            SellSignal = sellSignal;
        }
    }
}