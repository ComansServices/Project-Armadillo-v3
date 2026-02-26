import path from 'node:path';
import PDFDocument from 'pdfkit';

function wrapLine(input: string, maxChars = 110) {
  const words = input.split(/\s+/).filter(Boolean);
  const lines: string[] = [];
  let current = '';
  for (const word of words) {
    const next = current ? `${current} ${word}` : word;
    if (next.length > maxChars) {
      if (current) lines.push(current);
      current = word;
    } else {
      current = next;
    }
  }
  if (current) lines.push(current);
  return lines.length ? lines : [''];
}

function renderToBuffer(doc: any) {
  return new Promise<Buffer>((resolve, reject) => {
    const chunks: Buffer[] = [];
    doc.on('data', (c) => chunks.push(Buffer.isBuffer(c) ? c : Buffer.from(c)));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
    doc.end();
  });
}

export async function buildSimpleTextPdf(title: string, lines: string[]) {
  const doc = new PDFDocument({ size: 'A4', margin: 40 });
  doc.fontSize(16).text(title, { underline: true });
  doc.moveDown(0.5);
  doc.fontSize(11);
  for (const line of lines.slice(0, 220)) doc.text(line);
  return renderToBuffer(doc);
}

export async function buildBrandedReportPdf(options: {
  title: string;
  subtitle?: string;
  audience?: 'ops' | 'exec';
  generatedAt?: string;
  generatedFor?: string;
  dateRange?: string;
  confidentiality?: string;
  metricCards?: Array<{ label: string; value: string; tone?: 'critical' | 'high' | 'medium' | 'low' | 'neutral' }>;
  signoff?: { name: string; role?: string };
  sections: Array<{ heading: string; lines: string[] }>;
}) {
  const doc = new PDFDocument({ size: 'A4', margin: 40 });
  const generatedAt = options.generatedAt ?? new Date().toISOString();
  const audience = options.audience ?? 'ops';

  const brandRed = '#b92128';
  const brandSlate = '#3d4e5c';
  const logoPath = path.resolve(process.cwd(), 'apps/api/assets/comans-logo.png');

  const drawLogo = (x: number, y: number, w = 150, h = 52) => {
    try {
      doc.image(logoPath, x, y, { fit: [w, h], align: 'left', valign: 'top' });
    } catch {
      doc.fillColor(brandRed).fontSize(24).text('COMANS', x, y + 6);
      doc.fontSize(10).text('SERVICES', x + 95, y + 12);
    }
  };

  // Cover page
  drawLogo(40, 34, 180, 62);
  doc.rect(40, 120, 515, 2).fill(brandRed);
  doc.fillColor(brandSlate).fontSize(28).text(options.title, 40, 150, { width: 510 });
  doc.fillColor('#4b5563').fontSize(13).text(options.subtitle ?? (audience === 'exec' ? 'Executive summary view' : 'Operations detail view'), 40, 214, { width: 500 });

  const coverMeta = [
    `Generated for: ${options.generatedFor ?? 'Comans Internal Team'}`,
    `Report audience: ${audience.toUpperCase()}`,
    `Generated at: ${generatedAt}`,
    `Date range: ${options.dateRange ?? 'Current dataset snapshot'}`,
    `Classification: ${options.confidentiality ?? 'INTERNAL CONFIDENTIAL'}`
  ];

  let cy = 286;
  doc.fillColor(brandSlate).fontSize(11);
  for (const line of coverMeta) {
    doc.text(line, 56, cy, { width: 480 });
    cy += 22;
  }

  const toneFill: Record<string, string> = {
    critical: '#7f1d1d',
    high: '#991b1b',
    medium: '#92400e',
    low: '#1f2937',
    neutral: '#374151'
  };
  const cards = options.metricCards ?? [];
  if (cards.length) {
    const top = 416;
    const cardW = 118;
    const gap = 12;
    cards.slice(0, 4).forEach((card, idx) => {
      const x = 40 + idx * (cardW + gap);
      const fill = toneFill[card.tone ?? 'neutral'] ?? toneFill.neutral;
      doc.roundedRect(x, top, cardW, 78, 8).fill(fill);
      doc.fillColor('#ffffff').fontSize(10).text(card.label.toUpperCase(), x + 10, top + 10, { width: cardW - 20, align: 'center' });
      doc.fontSize(22).text(card.value, x + 10, top + 32, { width: cardW - 20, align: 'center' });
    });
  }

  doc.roundedRect(40, 700, 515, 92, 8).fillAndStroke('#f9fafb', '#e5e7eb');
  doc.fillColor(brandRed).fontSize(12).text('Confidentiality Notice', 56, 716);
  doc.fillColor('#4b5563').fontSize(10).text('This report contains operational and security information intended only for authorised recipients.', 56, 736, { width: 480 });

  const signoffName = options.signoff?.name ?? 'Comans Services';
  const signoffRole = options.signoff?.role ?? 'Authorised by Operations';
  doc.fillColor('#374151').fontSize(10).text(`Signed: ${signoffName}`, 56, 760, { width: 220 });
  doc.text(signoffRole, 56, 774, { width: 280 });

  // Detail page
  doc.addPage();
  drawLogo(40, 20, 130, 45);
  doc.fillColor(brandSlate).fontSize(17).text(options.title, 40, 70);
  doc.fontSize(9).fillColor('#55606b').text(`Generated ${generatedAt}`, 40, 88);
  doc.moveTo(40, 102).lineTo(555, 102).strokeColor('#d1d5db').stroke();

  let y = 114;
  for (const section of options.sections.slice(0, 16)) {
    if (y > 760) break;
    doc.fillColor(brandRed).fontSize(13).text(section.heading, 40, y);
    y = doc.y + 2;

    doc.fillColor(brandSlate).fontSize(10);
    for (const line of section.lines.slice(0, 80)) {
      for (const wrapped of wrapLine(line, 112)) {
        if (y > 770) break;
        doc.text(`• ${wrapped}`, 52, y, { width: 500, lineGap: 1 });
        y = doc.y + 1;
      }
      if (y > 770) break;
    }

    y += 8;
  }

  doc.fillColor('#6b7280').fontSize(9).text(`Audience: ${audience.toUpperCase()} • ${options.confidentiality ?? 'Internal Confidential'}`, 40, 805);

  return renderToBuffer(doc);
}
