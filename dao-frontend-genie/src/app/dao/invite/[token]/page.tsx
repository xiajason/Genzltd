import { InvitationAcceptPage } from '@/components/invitation-accept-page';

interface InvitationPageProps {
  params: {
    token: string;
  };
}

export default function InvitationPage({ params }: InvitationPageProps) {
  return <InvitationAcceptPage token={params.token} />;
}
