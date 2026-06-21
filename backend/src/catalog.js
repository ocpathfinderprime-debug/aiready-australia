export const purchaseLinks = {
  starterAudit: 'https://buy.stripe.com/8x200idHAep9bvRejYebu03',
  businessAudit: 'https://buy.stripe.com/bJecN4fPI1Cn9nJcbQebu04',
};

export const packages = [
  {
    id: 'starter_audit',
    name: 'AI Readiness Starter Audit',
    priceAud: 497,
    turnaround: '5 business days after intake completion',
    purchaseUrl: purchaseLinks.starterAudit,
    includes: [
      'AI readiness score',
      'tool shortlist',
      'priority workflow opportunities',
      '90-day roadmap',
    ],
    humanReview: true,
  },
  {
    id: 'business_audit',
    name: 'AI Readiness Business Audit',
    priceAud: 997,
    turnaround: '7 business days after intake completion',
    purchaseUrl: purchaseLinks.businessAudit,
    includes: [
      'workflow map',
      'opportunity register',
      'ROI estimate',
      'risk review',
      'implementation roadmap',
    ],
    humanReview: true,
  },
  {
    id: 'enterprise_assessment',
    name: 'Enterprise AI Capability Assessment',
    priceAud: null,
    turnaround: 'scoped after discovery',
    purchaseUrl: 'mailto:hello@aireadyaudit.com.au?subject=Enterprise%20AI%20Capability%20Assessment',
    includes: [
      'multi-team assessment',
      'governance review',
      'implementation portfolio',
      'stakeholder roadmap',
    ],
    humanReview: true,
  },
];

export const services = [
  'AI readiness audit',
  'AI tools audit',
  'AI automation audit',
  'AI governance review',
  'AI website visibility audit',
  'AI implementation sprint',
  'Enterprise AI capability assessment',
];

export const publicResources = [
  {
    uri: 'https://aireadyaudit.com.au/authority.html',
    name: 'AIReady Authority Hub',
    description: 'Public AI audit knowledge hub.',
  },
  {
    uri: 'https://aireadyaudit.com.au/llms.txt',
    name: 'AIReady llms.txt',
    description: 'AI-readable site and authority-page map.',
  },
  {
    uri: 'https://aireadyaudit.com.au/sitemap.xml',
    name: 'AIReady Sitemap',
    description: 'Canonical public URL index.',
  },
  {
    uri: 'https://aireadyaudit.com.au/schema-graph.jsonld',
    name: 'AIReady Schema Graph',
    description: 'Structured organisation, services, and authority data.',
  },
];

export const mcpTools = [
  {
    name: 'get_service_catalog',
    title: 'Get Service Catalog',
    risk: 'read',
    description: 'Return AIReady services, packages, public resources, and active purchase links.',
  },
  {
    name: 'create_lead',
    title: 'Create Lead',
    risk: 'write',
    description: 'Create a lead or intake record after user consent.',
  },
  {
    name: 'get_lead_status',
    title: 'Get Lead Status',
    risk: 'read',
    description: 'Return a stored lead status by record ID.',
  },
  {
    name: 'calculate_readiness_score',
    title: 'Calculate Readiness Score',
    risk: 'draft',
    description: 'Calculate a preliminary AI readiness score from intake signals.',
  },
  {
    name: 'verify_purchase_links',
    title: 'Verify Purchase Links',
    risk: 'read',
    description: 'Return configured purchase links and optionally run a live HTTP check.',
  },
];

export function getCatalog() {
  return {
    business: 'AIReady Australia',
    website: 'https://aireadyaudit.com.au',
    contactEmail: 'hello@aireadyaudit.com.au',
    packages,
    services,
    purchaseLinks,
    publicResources,
  };
}
