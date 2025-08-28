import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
 
class AnalyticsPage extends StatelessWidget { 
  const AnalyticsPage({super.key}); 
 
  @override 
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold( 
      backgroundColor: Colors.black, 
      appBar: AppBar( 
        backgroundColor: Colors.blue[900], 
        title: Text( 
          appLocalizations?.translate('analytics') ?? 'Analytics', 
          style: const TextStyle(color: Colors.white), 
        ), 
      ), 
      body: Padding( 
        padding: const EdgeInsets.all(16.0), 
        child: Column( 
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [ 
            // Tabs 
            Row( 
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
              children: [ 
                Text(appLocalizations?.translate('content') ?? 'Content', style: const TextStyle(color: Colors.white)), 
                Text(appLocalizations?.translate('sales') ?? 'Sales', style: const TextStyle(color: Colors.white)), 
                Text(appLocalizations?.translate('overview') ?? 'Overview', style: const TextStyle(color: Colors.white)), 
              ], 
            ), 
            const SizedBox(height: 20), 
 
            // Time Period 
            Text( 
              appLocalizations?.translate('timePeriod') ?? 'Time Period:', 
              style: const TextStyle(color: Colors.white), 
            ), 
            const SizedBox(height: 10), 
 
            // Week Dropdown 
            Container( 
              padding: const EdgeInsets.all(8), 
              color: Colors.blueGrey[800], 
              child: Text( 
                appLocalizations?.translate('week') ?? 'Week', 
                style: const TextStyle(color: Colors.white), 
              ), 
            ), 
            const SizedBox(height: 20), 
 
            // Cards Row 1 
            Row( 
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [ 
                _buildCard(appLocalizations?.translate('totalSales') ?? 'Total Sales', '0', Icons.shopping_cart, Colors.blue), 
                _buildCard(appLocalizations?.translate('totalProfit') ?? 'Total Profit', '0.0\$', Icons.attach_money, Colors.green), 
              ], 
            ), 
            const SizedBox(height: 20), 
 
            // Cards Row 2 
            Row( 
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [ 
                _buildCard(appLocalizations?.translate('conversionRate') ?? 'Conversion Rate', '%0', Icons.trending_down, Colors.orange), 
                _buildCard(appLocalizations?.translate('totalViews') ?? 'Total Views', '0', Icons.remove_red_eye, Colors.purple), 
              ], 
            ), 
            const SizedBox(height: 30), 
 
            // Revenue Trend 
            Text( 
              appLocalizations?.translate('revenueTrend') ?? 'Revenue Trend', 
              style: const TextStyle(color: Colors.white, fontSize: 18), 
            ), 
          ], 
        ), 
      ), 
    ); 
  } 
 
  Widget _buildCard(String title, String value, IconData icon, Color iconColor) { 
    return Container( 
      width: 150, 
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration( 
        color: Colors.grey[850], 
        borderRadius: BorderRadius.circular(8), 
      ), 
      child: Column( 
        children: [ 
          Icon(icon, color: iconColor, size: 28), 
          const SizedBox(height: 10), 
          Text( 
            title, 
            style: const TextStyle(color: Colors.white), 
          ), 
          const SizedBox(height: 5), 
          Text( 
            value, 
            style: const TextStyle(color: Colors.white, fontSize: 18), 
          ), 
        ], 
      ), 
    ); 
  } 
}