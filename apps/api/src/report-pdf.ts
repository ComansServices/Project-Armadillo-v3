function escapePdfText(input: string) {
  return input.replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)');
}

function wrapLine(input: string, maxChars = 95) {
  const words = input.split(/\s+/).filter(Boolean);
  const lines: string[] = [];
  let current = '';

  for (const word of words) {
    const candidate = current ? `${current} ${word}` : word;
    if (candidate.length > maxChars) {
      if (current) lines.push(current);
      current = word;
    } else {
      current = candidate;
    }
  }

  if (current) lines.push(current);
  return lines.length ? lines : [''];
}

export function buildSimpleTextPdf(title: string, lines: string[]) {
  const contentLines = [title, '', ...lines].slice(0, 180);
  let y = 790;
  const chunks: string[] = ['BT', '/F1 12 Tf'];

  for (const line of contentLines) {
    chunks.push(`1 0 0 1 40 ${y} Tm (${escapePdfText(line)}) Tj`);
    y -= 16;
    if (y < 40) break;
  }
  chunks.push('ET');

  const stream = chunks.join('\n');

  const objects: string[] = [];
  objects.push('1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj');
  objects.push('2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj');
  objects.push('3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj');
  objects.push('4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj');
  objects.push(`5 0 obj << /Length ${Buffer.byteLength(stream, 'utf8')} >> stream\n${stream}\nendstream endobj`);

  let body = '%PDF-1.4\n';
  const xref: number[] = [0];

  for (const obj of objects) {
    xref.push(Buffer.byteLength(body, 'utf8'));
    body += `${obj}\n`;
  }

  const xrefStart = Buffer.byteLength(body, 'utf8');
  body += `xref\n0 ${objects.length + 1}\n`;
  body += '0000000000 65535 f \n';
  for (let i = 1; i < xref.length; i += 1) {
    body += `${String(xref[i]).padStart(10, '0')} 00000 n \n`;
  }
  body += `trailer << /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xrefStart}\n%%EOF`;

  return Buffer.from(body, 'utf8');
}

export function buildBrandedReportPdf(options: {
  title: string;
  subtitle?: string;
  audience?: 'ops' | 'exec';
  generatedAt?: string;
  sections: Array<{ heading: string; lines: string[] }>;
}) {
  const generatedAt = options.generatedAt ?? new Date().toISOString();
  const audience = options.audience ?? 'ops';

  let y = 800;
  const chunks: string[] = ['BT'];

  // Header block
  chunks.push('/F1 20 Tf');
  chunks.push(`1 0 0 1 40 ${y} Tm (${escapePdfText('Comans Services • Armadillo')}) Tj`);
  y -= 28;

  chunks.push('/F1 16 Tf');
  chunks.push(`1 0 0 1 40 ${y} Tm (${escapePdfText(options.title)}) Tj`);
  y -= 20;

  chunks.push('/F1 11 Tf');
  const subtitle = options.subtitle ?? (audience === 'exec' ? 'Executive summary view' : 'Operations detail view');
  chunks.push(`1 0 0 1 40 ${y} Tm (${escapePdfText(subtitle)}) Tj`);
  y -= 16;
  chunks.push(`1 0 0 1 40 ${y} Tm (${escapePdfText(`Generated ${generatedAt}`)}) Tj`);
  y -= 22;

  for (const section of options.sections.slice(0, 12)) {
    if (y < 80) break;

    chunks.push('/F1 13 Tf');
    chunks.push(`1 0 0 1 40 ${y} Tm (${escapePdfText(section.heading)}) Tj`);
    y -= 16;

    chunks.push('/F1 11 Tf');
    for (const line of section.lines.slice(0, 60)) {
      const wrapped = wrapLine(line, 92);
      for (const w of wrapped) {
        if (y < 65) break;
        chunks.push(`1 0 0 1 52 ${y} Tm (${escapePdfText(w)}) Tj`);
        y -= 14;
      }
      if (y < 65) break;
    }

    y -= 8;
  }

  chunks.push('/F1 10 Tf');
  chunks.push(`1 0 0 1 40 34 Tm (${escapePdfText(`Audience: ${audience.toUpperCase()} • Internal Confidential`)}) Tj`);
  chunks.push('ET');

  const stream = chunks.join('\n');

  const objects: string[] = [];
  objects.push('1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj');
  objects.push('2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj');
  objects.push('3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >> endobj');
  objects.push('4 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj');
  objects.push(`5 0 obj << /Length ${Buffer.byteLength(stream, 'utf8')} >> stream\n${stream}\nendstream endobj`);

  let body = '%PDF-1.4\n';
  const xref: number[] = [0];

  for (const obj of objects) {
    xref.push(Buffer.byteLength(body, 'utf8'));
    body += `${obj}\n`;
  }

  const xrefStart = Buffer.byteLength(body, 'utf8');
  body += `xref\n0 ${objects.length + 1}\n`;
  body += '0000000000 65535 f \n';
  for (let i = 1; i < xref.length; i += 1) {
    body += `${String(xref[i]).padStart(10, '0')} 00000 n \n`;
  }
  body += `trailer << /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xrefStart}\n%%EOF`;

  return Buffer.from(body, 'utf8');
}
