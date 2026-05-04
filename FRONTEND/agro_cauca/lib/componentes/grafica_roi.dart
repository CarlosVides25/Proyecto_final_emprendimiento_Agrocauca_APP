
import 'package:flutter/material.dart';

class GraficaROI extends StatelessWidget {
  final double roi;
  const GraficaROI({super.key, required this.roi});

  @override
  Widget build(BuildContext context) {
    Color colorStatus = roi >= 20 ? Colors.green : (roi > 0 ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: (roi / 100).clamp(0.0, 1.0),
                  strokeWidth: 10,
                  color: colorStatus,
                  backgroundColor: colorStatus.withOpacity(0.1),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                "${roi.toStringAsFixed(1)}%",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorStatus),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ROI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(
                  "Rendimiento proyectado basado en inversión actual.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: colorStatus.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    roi >= 0 ? "Rentable" : "En Riesgo",
                    style: TextStyle(color: colorStatus, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}