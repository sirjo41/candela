<?php

namespace App\Filament\Widgets;

use App\Models\Redemption;
use Filament\Widgets\ChartWidget;

class RedemptionsChart extends ChartWidget
{
    // Remove static keyword here:
    protected ?string $heading = 'Redemption Activity Trend (تطور عمليات التفعيل)';
    
    protected static ?int $sort = 2;

    protected function getData(): array
    {
        $data = Redemption::selectRaw('MONTH(created_at) as month, COUNT(*) as count')
            ->groupBy('month')
            ->pluck('count', 'month')
            ->toArray();

        return [
            'datasets' => [
                [
                    'label' => 'Dynamic QR Scans',
                    'data' => array_values($data),
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