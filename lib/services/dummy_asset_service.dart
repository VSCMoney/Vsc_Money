import 'dart:convert';

import '../models/asset_model.dart';

/// Dummy service that provides mock data matching our API structure
/// Replace this with real API calls later
class DummyAssetService {

  /// Simulates API call with dummy data
  static Future<AssetData> fetchAssetData(String assetId, {List<String>? filters}) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500));

    // Return our comprehensive dummy data
    final jsonResponse = _getDummyJsonResponse();
    return AssetData.fromJson(jsonResponse);
  }

  /// Complete dummy JSON response matching our API structure
  static Map<String, dynamic> _getDummyJsonResponse() {
    return {
      "asset_id": "ZOMATO",
      "basic_info": {
        "name": "Zomato Limited",
        "symbol": "ZOMATO",
        "logo_url": "assets/images/microsoft.png",
        "description": "Zomato is an Indian multinational restaurant aggregator and food delivery company.",
        "sector": "Consumer Services",
        "industry": "Food Delivery",
        "exchange": "NSE",
        "currency": "INR"
      },
      "price_data": {
        "current_price": 3665.10,
        "change_amount": 174.30,
        "change_percent": 5.00,
        "is_positive": true,
        "open_price": 3650.00,
        "prev_close": 3491.80,
        "day_high": 3680.50,
        "day_low": 3620.00,
        "volume": "1,25,43,567",
        "lower_circuit": 3142.62,
        "upper_circuit": 3841.08,
        "last_updated": "2024-08-11T15:30:00Z"
      },
      "chart_data": {
        "time_series": {
          "ALL": [
            { "timestamp": "2021-07-23T00:00:00Z", "price": 76.00,  "volume": 5000000,  "high": 85.00,   "low": 70.00,   "open": 76.00 },
            { "timestamp": "2021-12-31T00:00:00Z", "price": 980.00, "volume": 12000000,"high": 1100.00, "low": 800.00,  "open": 900.00 },
            { "timestamp": "2022-08-11T00:00:00Z", "price": 1800.00,"volume": 3500000, "high": 2000.00, "low": 76.00,   "open": 76.00 },
            { "timestamp": "2023-03-31T00:00:00Z", "price": 2050.00,"volume": 6000000, "high": 2200.00, "low": 1800.00, "open": 1900.00 },
            { "timestamp": "2023-08-11T00:00:00Z", "price": 2200.00,"volume": 4200000, "high": 2400.00, "low": 1800.00, "open": 1800.00 },
            { "timestamp": "2023-12-31T00:00:00Z", "price": 2900.00,"volume": 7800000, "high": 3000.00, "low": 2200.00, "open": 2300.00 },
            { "timestamp": "2024-03-31T00:00:00Z", "price": 3100.00,"volume": 6800000, "high": 3400.00, "low": 3000.00, "open": 3200.00 },
            { "timestamp": "2024-08-11T00:00:00Z", "price": 3665.10,"volume": 6000000, "high": 4196.00, "low": 2200.00, "open": 2200.00 }
          ]
        },
        "default_period": "ALL"
      },
      "portfolio_data": {
        "shares": 15,
        "avg_price": 2450.30,
        "current_value": 54976.50,
        "change_percent": 8.5,
        "change_amount": 4288.50,
        "is_positive": true,
        "invested_amount": 36754.50,
        "unrealized_pnl": 18222.00
      },
      "performance_data": {
        "today_low": 3620.00,
        "today_high": 3680.50,
        "week_52_low": 2450.30,
        "week_52_high": 4196.00,
        "open_price": 3650.00,
        "prev_close": 3491.80,
        "volume": "1,25,43,567",
        "lower_circuit": 3142.62,
        "upper_circuit": 3841.08,
        "financial_metrics": {
          "market_cap": "₹25,473Cr",
          "roe": "1.33%",
          "pe_ratio": "75.58",
          "eps": "13.23",
          "pb_ratio": "1.18",
          "div_yield": "1.10%",
          "industry_pe": "45.54",
          "book_value": "847.61",
          "debt_to_equity": "0.33",
          "face_value": "10"
        },
        "financial_charts": {
          "revenue_quarterly": [
            { "period": "Jun '24", "value": 76 },
            { "period": "Sep '24", "value": 91 },
            { "period": "Dec '24", "value": 70 },
            { "period": "Mar '24", "value": 81 },
            { "period": "Jun '25", "value": 90 }
          ],
          "revenue_yearly": [
            { "period": "2021", "value": 280 },
            { "period": "2022", "value": 320 },
            { "period": "2023", "value": 350 },
            { "period": "2024", "value": 380 }
          ],
          "profit_quarterly": [
            { "period": "Jun '24", "value": 15 },
            { "period": "Sep '24", "value": 25 },
            { "period": "Dec '24", "value": 18 },
            { "period": "Mar '24", "value": 22 },
            { "period": "Jun '25", "value": 28 }
          ],
          "profit_yearly": [
            { "period": "2021", "value": 45 },
            { "period": "2022", "value": 65 },
            { "period": "2023", "value": 80 },
            { "period": "2024", "value": 88 }
          ],
          "net_worth_quarterly": [
            { "period": "Jun '24", "value": 1250 },
            { "period": "Sep '24", "value": 1320 },
            { "period": "Dec '24", "value": 1280 },
            { "period": "Mar '24", "value": 1350 },
            { "period": "Jun '25", "value": 1420 }
          ],
          "net_worth_yearly": [
            { "period": "2021", "value": 4800 },
            { "period": "2022", "value": 5200 },
            { "period": "2023", "value": 5600 },
            { "period": "2024", "value": 6000 }
          ],
          "value_unit": "Rs. CR"
        },
        "market_depth": {
          "buy_percentage": 37.66,
          "sell_percentage": 62.34,
          "bid_orders": [
            { "price": 3664.50, "quantity": 125 },
            { "price": 3664.00, "quantity": 89 },
            { "price": 3663.50, "quantity": 0 },
            { "price": 3663.00, "quantity": 234 },
            { "price": 3662.50, "quantity": 156 }
          ],
          "ask_orders": [
            { "price": 3665.00, "quantity": 1464 },
            { "price": 3665.50, "quantity": 189 },
            { "price": 3666.00, "quantity": 0 },
            { "price": 3666.50, "quantity": 345 },
            { "price": 3667.00, "quantity": 123 }
          ],
          "bid_total": 164634,
          "ask_total": 164634
        },
        "expandable_tiles": {
          "about_company": "Zomato is an Indian multinational restaurant aggregator and food delivery company.",
          "market_depth": {
            "buy_percentage": 45.20,
            "sell_percentage": 54.80,
            "bid_orders": [
              { "price": 3664.50, "quantity": 125 },
              { "price": 3664.00, "quantity": 89 },
              { "price": 3663.50, "quantity": 0 },
              { "price": 3663.00, "quantity": 234 },
              { "price": 3662.50, "quantity": 156 }
            ],
            "ask_orders": [
              { "price": 3665.00, "quantity": 2456 },
              { "price": 3665.50, "quantity": 189 },
              { "price": 3666.00, "quantity": 0 },
              { "price": 3666.50, "quantity": 345 },
              { "price": 3667.00, "quantity": 123 }
            ],
            "bid_total": 245680,
            "ask_total": 298450
          },
          "fundamentals": {
            "market_cap": "₹25,473Cr",
            "roe": "1.33%",
            "pe_ratio": "75.58",
            "eps": "13.23",
            "pb_ratio": "1.18",
            "div_yield": "1.10%",
            "industry_pe": "45.54",
            "book_value": "847.61",
            "debt_to_equity": "0.33",
            "face_value": "10"
          },
          "financials": {
            "revenue_quarterly": [
              { "period": "Jun '24", "value": 76 },
              { "period": "Sep '24", "value": 91 },
              { "period": "Dec '24", "value": 70 },
              { "period": "Mar '24", "value": 81 },
              { "period": "Jun '25", "value": 90 }
            ],
            "revenue_yearly": [
              { "period": "2021", "value": 280 },
              { "period": "2022", "value": 320 },
              { "period": "2023", "value": 350 },
              { "period": "2024", "value": 380 }
            ],
            "profit_quarterly": [],
            "profit_yearly": [],
            "net_worth_quarterly": [],
            "net_worth_yearly": [],
            "value_unit": "Rs. CR"
          },
          "shareholding_pattern": {
            "time_periods": ["Jun '24", "Sep '24", "Dec '24", "Mar '24", "Jun '25"],
            "shareholding_data": [
              {
                "Promoters": 0.3798,
                "Retail & Others": 0.25,
                "Foreign Institutions": 0.15,
                "Other Domestic Institutions": 0.3798,
                "Mutual Funds": 0.25
              },
              {
                "Promoters": 0.4,
                "Retail & Others": 0.2,
                "Foreign Institutions": 0.1,
                "Other Domestic Institutions": 0.3,
                "Mutual Funds": 0.3
              },
              {
                "Promoters": 0.35,
                "Retail & Others": 0.3,
                "Foreign Institutions": 0.1,
                "Other Domestic Institutions": 0.3,
                "Mutual Funds": 0.2
              },
              {
                "Promoters": 0.3,
                "Retail & Others": 0.35,
                "Foreign Institutions": 0.2,
                "Other Domestic Institutions": 0.25,
                "Mutual Funds": 0.3
              },
              {
                "Promoters": 0.42,
                "Retail & Others": 0.18,
                "Foreign Institutions": 0.15,
                "Other Domestic Institutions": 0.25,
                "Mutual Funds": 0.22
              }
            ],
            "default_selected_index": 0
          }
        }
      },
      "fundamentals": {
        "insights": [
          {
            "image_name": "assets/images/upward.png",
            "title": "Market Leadership",
            "description": "Dominant position with strong brand recognition."
          },
          {
            "image_name": "assets/images/downward.png",
            "title": "Revenue Growth",
            "description": "Consistent growth with expanding services."
          },
          {
            "image_name": "assets/images/eye.png",
            "title": "Path to Profitability",
            "description": "Focus on sustainable profitability."
          }
        ],
        "market_insight": "Trading at ₹3,665.10; strong bullish momentum today.",
        "for_you_card": {
          "title": "Market Insight",
          "content": "Breaking above resistance; supported by positive results."
        }
      },
      "technicals": {
        "insights": [
          {
            "title": "Bullish Momentum",
            "description": "RSI and price action indicate strength."
          },
          {
            "title": "Support Levels",
            "description": "Support around ₹3,500; resistance ~₹3,700."
          }
        ],
        "indicators": [
          { "name": "RSI (14)", "value": 68.5, "signal": "BUY", "description": "RSI above 60 is bullish" },
          { "name": "MACD", "value": 25.3, "signal": "BUY", "description": "MACD line > signal line" }
        ]
      },
      "news": [
        {
          "title": "Zomato Reports Strong Q2 Results, Revenue Up 15%",
          "description": "Robust second-quarter results driven by higher order volumes.",
          "source": "Economic Times",
          "time_ago": "2 hours",
          "image_url": null,
          "published_at": "2024-08-11T13:30:00Z",
          "url": "https://economictimes.com/zomato-q2-results"
        }
      ],
      "events": [
        {
          "title": "Q2 FY25 Earnings Call",
          "description": "Quarterly earnings call and outlook.",
          "event_date": "2024-08-15T16:00:00Z",
          "event_type": "EARNINGS",
          "is_upcoming": true
        }
      ],
      "futures_options": {
        "futures": [
          {
            "symbol": "ZOMATO24AUG",
            "expiry": "2024-08-29T15:30:00Z",
            "price": 3670.50,
            "change_amount": 178.20,
            "change_percent": 5.1,
            "volume": "45,678",
            "open_interest": "1,23,456"
          }
        ],
        "options": [
          {
            "symbol": "ZOMATO24AUG3700CE",
            "expiry": "2024-08-29T15:30:00Z",
            "strike_price": 3700.0,
            "option_type": "CALL",
            "price": 45.50,
            "change_amount": 12.30,
            "change_percent": 37.1,
            "volume": "12,456",
            "open_interest": "45,678",
            "implied_volatility": 28.5
          }
        ]
      },
      "additional_data": {
        "data_freshness": "2024-08-11T15:30:00Z",
        "market_status": "OPEN",
        "currency_symbol": "₹",
        "timezone": "Asia/Kolkata",

        "user_notes": [
          {
            "id": "n1",
            "title": "Q1 Results Takeaway",
            "content": "Revenue growth beat expectations, but margins compressed.",
            "created_at": "2024-08-01T10:30:00Z"
          },
          {
            "id": "n2",
            "title": "Competition",
            "content": "Swiggy expansion could pressure market share near-term.",
            "created_at": "2024-08-05T08:00:00Z"
          }
        ],
        "user_watchlisted": true,
        "watchlist_stocks": [
          {
            "symbol": "ZOMATO",
            "name": "Zomato Limited",
            "logo_url": "assets/images/microsoft.png",
            "current_price": 3665.10,
            "change_percent": 5.0,
            "is_positive": true
          },
          {
            "symbol": "INFY",
            "name": "Infosys Limited",
            "logo_url": "assets/images/infy.png",
            "current_price": 1550.20,
            "change_percent": -0.8,
            "is_positive": false
          },
          {
            "symbol": "RELIANCE",
            "name": "Reliance Industries",
            "logo_url": "assets/images/reliance.png",
            "current_price": 2875.00,
            "change_percent": 1.2,
            "is_positive": true
          }
        ]
      }
    };

  }
}