import AppNavbar from "@/components/shared/AppNavbar";
import Footer from "@/components/shared/Footer";

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <AppNavbar />
      <main>{children}</main>
    </>
  );
}
