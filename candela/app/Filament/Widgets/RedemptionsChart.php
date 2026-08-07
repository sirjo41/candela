<?php

namespace App\Filament\Widgets;

use App\Models\Redemption;
use Filament\Widgets\ChartWidget;

class RedemptionsChart extends ChartWidget
{
    protected ?string $heading = 'Redemption Activity Trend (تطور عمليات التفعيل)';

    protected static ?int $sort = 2;

    protected function getData(): array
    {
        $driver = (new Redemption)->getConnection()->getDriverName();
        if ($driver === 'sqlite') {
            $rawCounts = Redemption::selectRaw("cast(strftime('%m', created_at) as integer) as month, COUNT(*) as count")
                ->groupBy('month')
                ->pluck('count', 'month')
                ->toArray();
        } else {
            $rawCounts = Redemption::selectRaw('MONTH(created_at) as month, COUNT(*) as count')
                ->groupBy('month')
                ->pluck('count', 'month')
                ->toArray();
        }

        $monthlyData = array_fill(1, 12, 0);
        foreach ($rawCounts as $month => $count) {
            $monthNum = (int) $month;
            if ($monthNum >= 1 && $monthNum <= 12) {
                $monthlyData[$monthNum] = (int) $count;
            }
        }

        return [
            'datasets' => [
                [
                    'label' => 'Dynamic QR Scans',
                    'data' => array_values($monthlyData),
                    'borderColor' => '#3b82f6',
                ],
            ],
            'labels' => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}