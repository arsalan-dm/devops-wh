import { LightningElement, api } from 'lwc';
import ChartJs from '@salesforce/resourceUrl/ChartJs';
import { loadScript } from 'lightning/platformResourceLoader';

export default class ChartExample extends LightningElement {
    @api type = 'line'; // Set default type to 'line'
    @api chartLabels = '';  // Labels for time periods
    @api kpiData1 = '';  // Data for KPI 1
    @api kpiData2 = '';  // Data for KPI 2
    @api kpiData3 = '';  // Data for KPI 3
    @api kpiData4 = '';  // Data for KPI 4
    @api kpiData5 = '';  // Data for KPI 5
    @api kpiLabels = ''; // Labels for KPIs
    @api kpiColors = ''; // Line colors for the datasets
    @api chartHeight = '400'; // Default height to 400px
    @api pointSize = '0'; // Point sie on line graph
    @api fillData = 'false'; // Fills bar or space below line chart
true

    chart;

    renderedCallback() {
        if (this.chart) {
            return; // Chart already initialized
        }

        loadScript(this, ChartJs)
            .then(() => {
                console.log('✅ Chart.js loaded successfully:', window.Chart);
                this.initializeChart();
            })
            .catch(error => {
                console.error('❌ Error loading Chart.js:', error);
            });
    }

    initializeChart() {
        try {
            // Parse chart labels (month names or numbers)
            const parsedLabels = this.chartLabels ? this.chartLabels.split(',').map(label => label.trim()) : [];
    
            const kpiDatasets = [
                { data: this.kpiData1, label: this.kpiLabels.split(',')[0] || 'KPI 1', color: this.kpiColors.split(',')[0] || '#FF5733' },
                { data: this.kpiData2, label: this.kpiLabels.split(',')[1] || 'KPI 2', color: this.kpiColors.split(',')[1] || '#33FF57' },
                { data: this.kpiData3, label: this.kpiLabels.split(',')[2] || 'KPI 3', color: this.kpiColors.split(',')[2] || '#3357FF' },
                { data: this.kpiData4, label: this.kpiLabels.split(',')[3] || 'KPI 4', color: this.kpiColors.split(',')[3] || '#FFCE56' },
                { data: this.kpiData5, label: this.kpiLabels.split(',')[4] || 'KPI 5', color: this.kpiColors.split(',')[4] || '#FF33A8' }
            ].filter(kpi => kpi.data); //


           // Transform data into proper format
        const datasets = kpiDatasets.map((kpi, index) => ({
            label: kpi.label,
            data: kpi.data.split(',').map((value, i) => ({ x: i + 1, y: Number(value.replace(/,/g, '').trim()) })),
            borderColor: kpi.color,
            borderWidth: 2,
            backgroundColor: kpi.color, // Convert string to boolean
            fill: this.fillData === 'true' // Convert string to boolean
        }));
    
            // Apply dynamic height to canvas
            const canvas = this.template.querySelector('canvas');
            if (canvas) {
                canvas.style.height = `${this.chartHeight}px`;
            }
    
            const ctx = this.template.querySelector('canvas').getContext('2d');
            this.chart = new Chart(ctx, {
                type: this.type, // Define chart type (line, bar, etc.)
                data: {
                    labels: parsedLabels,
                    datasets: datasets
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    elements: {
                        point: {
                            radius: this.pointSize,
                            hitRadius: this.pointSize
                        }
                    },

                    legend: {
                            display: true,
                            position: 'bottom',
                            align: 'center',
                            labels: {
                                boxWidth: 20,
                                padding: 10,
                                color: '#000000',  // Text color for legend
                                boxHeight: 20  // Box height for legend items
                            }
                        },
                    scales: {
                        x: {
                            type: 'linear', // To treat the x-axis as numerical (month number)
                            position: 'bottom',
                            grid: {
                                drawOnChartArea: false,  // Remove grid lines behind chart
                            }
                        },
                        y: {
                            ticks: {
                                beginAtZero: true
                            },
                            grid: {
                                drawOnChartArea: false,  // Remove grid lines behind chart
                            }
                        }
                    },
                    layout: {
                        padding: {
                            left: 10,
                            right: 10,
                            top: 10,
                            bottom: 10
                        }
                    }
                }
            });
    
            console.log('✅ Chart created successfully:', this.chart);
    
        } catch (error) {
            console.error('❌ Error initializing chart:', error.message || error);
        }
    }
    
    
}