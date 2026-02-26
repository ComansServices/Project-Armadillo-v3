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
  sections: Array<{ heading: string; lines: string[] }>;
}) {
  const doc = new PDFDocument({ size: 'A4', margin: 40 });
  const generatedAt = options.generatedAt ?? new Date().toISOString();
  const audience = options.audience ?? 'ops';

  const brandRed = '#b92128';
  const brandSlate = '#3d4e5c';

  const logoPath = path.resolve(process.cwd(), 'apps/api/assets/comans-logo.png');
  try {
    doc.image(logoPath, 40, 28, { fit: [140, 48], align: 'left', valign: 'top' });
  } catch {
    doc.fillColor(brandRed).fontSize(22).text('COMANS', 40, 34);
    doc.fontSize(10).text('SERVICES', 135, 40);
  }

  doc.fillColor(brandSlate).fontSize(17).text(options.title, 40, 88);
  doc.fontSize(11).text(options.subtitle ?? (audience === 'exec' ? 'Executive summary view' : 'Operations detail view'), 40, 110);
  doc.fontSize(9).fillColor('#55606b').text(`Generated ${generatedAt}`, 40, 126);
  doc.moveTo(40, 142).lineTo(555, 142).strokeColor('#d1d5db').stroke();

  let y = 152;
  for (const section of options.sections.slice(0, 12)) {
    if (y > 760) break;
    doc.fillColor(brandRed).fontSize(13).text(section.heading, 40, y);
    y = doc.y + 2;

    doc.fillColor(brandSlate).fontSize(10);
    for (const line of section.lines.slice(0, 60)) {
      for (const wrapped of wrapLine(line, 112)) {
        if (y > 770) break;
        doc.text(`• ${wrapped}`, 52, y, { width: 500, lineGap: 1 });
        y = doc.y + 1;
      }
      if (y > 770) break;
    }

    y += 8;
  }

  doc.fillColor('#6b7280').fontSize(9).text(`Audience: ${audience.toUpperCase()} • Internal Confidential`, 40, 805);

  return renderToBuffer(doc);
}
